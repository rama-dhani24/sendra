import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/constants.dart';

/// Reads live exchange rates from Firestore ( /config/exchange_rates )
/// and exposes them as a stream so the UI rebuilds automatically.
///
/// The Cloud Function writes to this document every 30 minutes.
/// Flutter never calls ExchangeRate-API or CoinGecko directly.
///
/// Usage (in main.dart or a provider):
///   ExchangeRateService.instance.init();
///
/// Then anywhere in the app:
///   AppRates.usdtToTzs   // always reflects live data
///   ExchangeRateService.instance.stream  // stream of RateSnapshot
class ExchangeRateService {
  ExchangeRateService._();
  static final instance = ExchangeRateService._();

  final _firestore = FirebaseFirestore.instance;

  // Broadcast stream — multiple widgets can listen simultaneously
  final _controller = StreamController<RateSnapshot>.broadcast();
  Stream<RateSnapshot> get stream => _controller.stream;

  StreamSubscription<DocumentSnapshot>? _sub;
  RateSnapshot? _latest;
  RateSnapshot? get latest => _latest;

  /// Call once on app start (e.g. in main.dart after Firebase.initializeApp).
  void init() {
    _sub = _firestore
        .collection('config')
        .doc('exchange_rates')
        .snapshots()
        .listen(_onSnapshot, onError: _onError);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }

  void _onSnapshot(DocumentSnapshot doc) {
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;

    try {
      final snapshot = RateSnapshot.fromFirestore(data);
      _latest = snapshot;

      // Patch AppRates using named parameters — matches constants.dart signature
      AppRates.applyLiveRates(
        newUsdtToTzs: snapshot.usdtToTzs,
        newFiat: snapshot.fiat,
        newCrypto: snapshot.crypto,
        newSpread: snapshot.spread,
        newFeeRate: snapshot.feeRate,
      );

      _controller.add(snapshot);
    } catch (e, st) {
      // Malformed document — keep using whatever we had before
      _controller.addError(ExchangeRateError('Failed to parse rates: $e'), st);
    }
  }

  void _onError(Object error, StackTrace st) {
    _controller.addError(ExchangeRateError('Firestore read error: $error'), st);
  }
}

// ─── Rate Snapshot ─────────────────────────────────────────────────────────
/// Immutable snapshot of all rates from Firestore.
class RateSnapshot {
  /// 1 unit of currency → USDT (mid-market, no spread applied yet)
  final Map<String, double> fiat;

  /// 1 USDT = X TZS (receiving-side rate)
  final double usdtToTzs;

  /// Crypto prices in USD
  final Map<String, double> crypto;

  /// Business config
  final double spread;
  final double feeRate;

  final DateTime? updatedAt;

  const RateSnapshot({
    required this.fiat,
    required this.usdtToTzs,
    required this.crypto,
    required this.spread,
    required this.feeRate,
    this.updatedAt,
  });

  factory RateSnapshot.fromFirestore(Map<String, dynamic> data) {
    Map<String, double> parseMap(dynamic raw) {
      if (raw == null) return {};
      return (raw as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    }

    final config = data['config'] as Map<String, dynamic>? ?? {};
    final ts = data['updatedAt'];

    return RateSnapshot(
      fiat: parseMap(data['fiat']),
      usdtToTzs: (data['usdtToTzs'] as num?)?.toDouble() ?? 2650.0,
      crypto: parseMap(data['crypto']),
      spread: (config['spread'] as num?)?.toDouble() ?? 0.015,
      feeRate: (config['feeRate'] as num?)?.toDouble() ?? 0.01,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  /// Convenience: 1 fiat currency → USDT after spread
  double fiatToUsdt(String currency, double amount) {
    if (currency == 'USDT') return amount * (1 - spread);
    final rate = fiat[currency] ?? 1.0;
    return amount * rate * (1 - spread);
  }

  /// Convenience: USDT → TZS (receive side, no extra spread here)
  double usdtToTzsAmount(double usdt) => usdt * usdtToTzs;

  /// Full send path: fiat/USDT → TZS received
  double toTzs(String currency, double amount) =>
      usdtToTzsAmount(fiatToUsdt(currency, amount));
}

// ─── Error type ────────────────────────────────────────────────────────────
class ExchangeRateError implements Exception {
  final String message;
  const ExchangeRateError(this.message);
  @override
  String toString() => 'ExchangeRateError: $message';
}
