import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/constants.dart';

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
  final double rate; // USDT/TZS rate used
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

  // ── Buy USDT: spend TZS, receive USDT ─────────────────────────────────────
  // tzsAmount = how much TZS the user wants to spend
  // Returns USDT credited after 1% fee
  static Future<ExchangeResult> buyUsdt({
    required String userId,
    required double tzsAmount,
  }) async {
    if (tzsAmount <= 0) throw 'Amount must be greater than 0.';

    final fee = _fee(tzsAmount);
    final tzsAfterFee = tzsAmount - fee;
    final usdtReceived = AppRates.tzsToUsdt(tzsAfterFee);
    final rate = AppRates.usdtToTzs;

    final ref = _db.collection(FSKeys.usersCollection).doc(userId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data()!;
      final balTzs = (data[FSKeys.balanceTzs] as num).toDouble();
      final balUsdt = (data[FSKeys.balanceUsdt] as num? ?? 0).toDouble();

      if (balTzs < tzsAmount) {
        throw 'Insufficient TZS balance. You have '
            'TZS ${Validators.formatNumber(balTzs)}.';
      }

      txn.update(ref, {
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
    });

    // Notification
    await _db.collection(FSKeys.notificationsCollection).add({
      NotifKeys.userId: userId,
      NotifKeys.title: 'Exchange Completed',
      NotifKeys.body:
          'Bought ${Validators.formatUsdt(usdtReceived)} USDT '
          'for TZS ${Validators.formatNumber(tzsAmount)}.',
      NotifKeys.type: 'exchange',
      NotifKeys.txId: exRef.id,
      NotifKeys.amount: tzsAmount,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });

    return result;
  }

  // ── Sell USDT: spend USDT, receive TZS ────────────────────────────────────
  // usdtAmount = how much USDT the user wants to sell
  static Future<ExchangeResult> sellUsdt({
    required String userId,
    required double usdtAmount,
  }) async {
    if (usdtAmount <= 0) throw 'Amount must be greater than 0.';

    final grossTzs = AppRates.usdtToTzsAmount(usdtAmount);
    final fee = _fee(grossTzs);
    final tzsReceived = grossTzs - fee;
    final rate = AppRates.usdtToTzs;

    final ref = _db.collection(FSKeys.usersCollection).doc(userId);

    await _db.runTransaction((txn) async {
      final snap = await txn.get(ref);
      final data = snap.data()!;
      final balTzs = (data[FSKeys.balanceTzs] as num).toDouble();
      final balUsdt = (data[FSKeys.balanceUsdt] as num? ?? 0).toDouble();

      if (balUsdt < usdtAmount) {
        throw 'Insufficient USDT balance. You have '
            '${Validators.formatUsdt(balUsdt)} USDT.';
      }

      txn.update(ref, {
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
    });

    // Notification
    await _db.collection(FSKeys.notificationsCollection).add({
      NotifKeys.userId: userId,
      NotifKeys.title: 'Exchange Completed',
      NotifKeys.body:
          'Sold ${Validators.formatUsdt(usdtAmount)} USDT. '
          'Received TZS ${Validators.formatNumber(tzsReceived)}.',
      NotifKeys.type: 'exchange',
      NotifKeys.txId: exRef.id,
      NotifKeys.amount: tzsReceived,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });

    return result;
  }

  static double _fee(double amount) =>
      double.parse((amount * AppRates.exchangeFeeRate).toStringAsFixed(2));
}
