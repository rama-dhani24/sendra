import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/services/exchange_rate_service.dart';

enum ExchangeDirection { buyUsdt, sellUsdt }

// ─── Exchange result model ──────────────────────────────────────────────────
class ExchangeResult {
  final String id;
  final ExchangeDirection direction;
  final double fromAmount;
  final String fromCurrency;
  final double toAmount;
  final String toCurrency;
  final double feeTzs;
  final double rate;
  final DateTime createdAt;

  const ExchangeResult({
    required this.id,
    required this.direction,
    required this.fromAmount,
    required this.fromCurrency,
    required this.toAmount,
    required this.toCurrency,
    required this.feeTzs,
    required this.rate,
    required this.createdAt,
  });

  String get directionLabel =>
      direction == ExchangeDirection.buyUsdt ? 'buy_usdt' : 'sell_usdt';
}

// ─── Exchange service ────────────────────────────────────────────────────────
class ExchangeService {
  static final _db = FirebaseFirestore.instance;

  // Returns the current RateSnapshot, falling back to AppRates defaults
  // if live rates haven't loaded yet (e.g. no internet on first launch).
  static RateSnapshot? get _rates => ExchangeRateService.instance.latest;

  static double get _usdtToTzs => _rates?.usdtToTzs ?? AppRates.usdtToTzs;

  static double get _feeRate => _rates?.feeRate ?? AppRates.exchangeFeeRate;

  // ── Preview helpers (call these from the UI before confirming) ─────────────

  /// How much USDT the user receives if they spend [tzsAmount].
  static ExchangePreview previewBuyUsdt(double tzsAmount) {
    final fee = _calcFee(tzsAmount);
    final tzsAfterFee = tzsAmount - fee;
    final usdtReceived = tzsAfterFee / _usdtToTzs;
    return ExchangePreview(
      inputAmount: tzsAmount,
      inputCurrency: 'TZS',
      outputAmount: usdtReceived,
      outputCurrency: 'USDT',
      feeTzs: fee,
      rate: _usdtToTzs,
    );
  }

  /// How much TZS the user receives if they sell [usdtAmount].
  static ExchangePreview previewSellUsdt(double usdtAmount) {
    final grossTzs = usdtAmount * _usdtToTzs;
    final fee = _calcFee(grossTzs);
    final tzsReceived = grossTzs - fee;
    return ExchangePreview(
      inputAmount: usdtAmount,
      inputCurrency: 'USDT',
      outputAmount: tzsReceived,
      outputCurrency: 'TZS',
      feeTzs: fee,
      rate: _usdtToTzs,
    );
  }

  // ── Buy USDT: spend TZS, receive USDT ─────────────────────────────────────
  static Future<ExchangeResult> buyUsdt({
    required String userId,
    required double tzsAmount,
  }) async {
    if (tzsAmount <= 0) throw 'Amount must be greater than 0.';

    // Snapshot the live rate at execution time — rate is locked in for this tx
    final rate = _usdtToTzs;
    final fee = _calcFee(tzsAmount);
    final tzsAfterFee = tzsAmount - fee;
    final usdtReceived = tzsAfterFee / rate;

    final userRef = _db.collection(FSKeys.usersCollection).doc(userId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(userRef);
      final data = snap.data()!;
      final balTzs = (data[FSKeys.balanceTzs] as num).toDouble();
      final balUsdt = (data[FSKeys.balanceUsdt] as num? ?? 0).toDouble();

      if (balTzs < tzsAmount) {
        throw 'Insufficient TZS balance. '
            'You have TZS ${Validators.formatNumber(balTzs)}.';
      }

      txn.update(userRef, {
        FSKeys.balanceTzs: balTzs - tzsAmount,
        FSKeys.balanceUsdt: balUsdt + usdtReceived,
      });
    });

    final exRef = _db.collection(FSKeys.exchangesCollection).doc();
    final result = ExchangeResult(
      id: exRef.id,
      direction: ExchangeDirection.buyUsdt,
      fromAmount: tzsAmount,
      fromCurrency: 'TZS',
      toAmount: usdtReceived,
      toCurrency: 'USDT',
      feeTzs: fee,
      rate: rate,
      createdAt: DateTime.now(),
    );

    await exRef.set({
      ExKeys.userId: userId,
      ExKeys.direction: result.directionLabel,
      ExKeys.fromAmount: tzsAmount,
      ExKeys.fromCurrency: 'TZS',
      ExKeys.toAmount: usdtReceived,
      ExKeys.toCurrency: 'USDT',
      ExKeys.feeTzs: fee,
      ExKeys.rate: rate,
      ExKeys.createdAt: FieldValue.serverTimestamp(),
      ExKeys.status: 'completed',
      // Store the rate source so you can audit whether it was live or fallback
      'rateSrc': _rates != null ? 'live' : 'fallback',
    });

    await _addNotification(
      userId: userId,
      title: 'Exchange Completed',
      body:
          'Bought ${Validators.formatUsdt(usdtReceived)} USDT '
          'for TZS ${Validators.formatNumber(tzsAmount)}.',
      txId: exRef.id,
      amount: tzsAmount,
    );

    return result;
  }

  // ── Sell USDT: spend USDT, receive TZS ────────────────────────────────────
  static Future<ExchangeResult> sellUsdt({
    required String userId,
    required double usdtAmount,
  }) async {
    if (usdtAmount <= 0) throw 'Amount must be greater than 0.';

    final rate = _usdtToTzs;
    final grossTzs = usdtAmount * rate;
    final fee = _calcFee(grossTzs);
    final tzsReceived = grossTzs - fee;

    final userRef = _db.collection(FSKeys.usersCollection).doc(userId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(userRef);
      final data = snap.data()!;
      final balTzs = (data[FSKeys.balanceTzs] as num).toDouble();
      final balUsdt = (data[FSKeys.balanceUsdt] as num? ?? 0).toDouble();

      if (balUsdt < usdtAmount) {
        throw 'Insufficient USDT balance. '
            'You have ${Validators.formatUsdt(balUsdt)} USDT.';
      }

      txn.update(userRef, {
        FSKeys.balanceTzs: balTzs + tzsReceived,
        FSKeys.balanceUsdt: balUsdt - usdtAmount,
      });
    });

    final exRef = _db.collection(FSKeys.exchangesCollection).doc();
    final result = ExchangeResult(
      id: exRef.id,
      direction: ExchangeDirection.sellUsdt,
      fromAmount: usdtAmount,
      fromCurrency: 'USDT',
      toAmount: tzsReceived,
      toCurrency: 'TZS',
      feeTzs: fee,
      rate: rate,
      createdAt: DateTime.now(),
    );

    await exRef.set({
      ExKeys.userId: userId,
      ExKeys.direction: result.directionLabel,
      ExKeys.fromAmount: usdtAmount,
      ExKeys.fromCurrency: 'USDT',
      ExKeys.toAmount: tzsReceived,
      ExKeys.toCurrency: 'TZS',
      ExKeys.feeTzs: fee,
      ExKeys.rate: rate,
      ExKeys.createdAt: FieldValue.serverTimestamp(),
      ExKeys.status: 'completed',
      'rateSrc': _rates != null ? 'live' : 'fallback',
    });

    await _addNotification(
      userId: userId,
      title: 'Exchange Completed',
      body:
          'Sold ${Validators.formatUsdt(usdtAmount)} USDT. '
          'Received TZS ${Validators.formatNumber(tzsReceived)}.',
      txId: exRef.id,
      amount: tzsReceived,
    );

    return result;
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  static double _calcFee(double amount) =>
      double.parse((amount * _feeRate).toStringAsFixed(2));

  static Future<void> _addNotification({
    required String userId,
    required String title,
    required String body,
    required String txId,
    required double amount,
  }) async {
    await _db.collection(FSKeys.notificationsCollection).add({
      NotifKeys.userId: userId,
      NotifKeys.title: title,
      NotifKeys.body: body,
      NotifKeys.type: 'exchange',
      NotifKeys.txId: txId,
      NotifKeys.amount: amount,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });
  }
}

// ─── Preview model (shown in UI before user confirms) ──────────────────────
class ExchangePreview {
  final double inputAmount;
  final String inputCurrency;
  final double outputAmount;
  final String outputCurrency;
  final double feeTzs;
  final double rate;

  const ExchangePreview({
    required this.inputAmount,
    required this.inputCurrency,
    required this.outputAmount,
    required this.outputCurrency,
    required this.feeTzs,
    required this.rate,
  });

  /// Human-readable summary line for the confirmation sheet
  String get summary =>
      '${Validators.formatNumber(inputAmount)} $inputCurrency → '
      '${outputCurrency == 'USDT' ? Validators.formatUsdt(outputAmount) : Validators.formatNumber(outputAmount)} $outputCurrency';

  String get feeLabel => 'Fee: TZS ${Validators.formatNumber(feeTzs)}';

  String get rateLabel => '1 USDT = TZS ${Validators.formatNumber(rate)}';
}
