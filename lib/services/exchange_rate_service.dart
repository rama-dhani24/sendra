import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/constants.dart';

// ─── Rate snapshot ────────────────────────────────────────────────────────────
class RateSnapshot {
  final double usdtToTzs;
  final double spread;
  final double feeRate;
  final Map<String, double> fiat;
  final Map<String, double> crypto;
  final DateTime updatedAt;

  const RateSnapshot({
    required this.usdtToTzs,
    required this.spread,
    required this.feeRate,
    required this.fiat,
    required this.crypto,
    required this.updatedAt,
  });

  // Convert any supported currency to TZS using live rates
  double toTzs(String currency, double amount) {
    if (currency == 'TZS') return amount;
    if (currency == 'USDT') return amount * (1 - spread) * usdtToTzs;
    final fiatRate = fiat[currency];
    if (fiatRate != null) return amount * fiatRate * (1 - spread) * usdtToTzs;
    final cryptoUsd = crypto[currency];
    if (cryptoUsd != null) return amount * cryptoUsd * (1 - spread) * usdtToTzs;
    return 0;
  }
}

// ─── Exchange Rate Service ────────────────────────────────────────────────────
// Singleton — subscribes once to Firestore on init(), patches AppRates in place,
// and exposes a broadcast stream so any number of widgets can listen cheaply.
class ExchangeRateService {
  ExchangeRateService._();
  static final instance = ExchangeRateService._();

  // ── Internal state ────────────────────────────────────────────────────────
  final _controller = StreamController<RateSnapshot>.broadcast();
  StreamSubscription? _firestoreSub;
  RateSnapshot? _latest;
  bool _initialized = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// The broadcast stream — safe to listen to from multiple widgets.
  /// Immediately emits the last snapshot if one is already loaded.
  Stream<RateSnapshot> get stream {
    if (_latest != null) {
      // Emit cached value immediately so widgets don't show loading
      return _controller.stream.startWithValue(_latest!);
    }
    return _controller.stream;
  }

  /// Latest snapshot, or null if not yet loaded.
  RateSnapshot? get latest => _latest;

  /// Call once from main() — sets up the single Firestore subscription.
  void init() {
    if (_initialized) return;
    _initialized = true;

    _firestoreSub = FirebaseFirestore.instance
        .collection('config')
        .doc('exchange_rates')
        .snapshots()
        .listen(_onDoc, onError: _onError);
  }

  void dispose() {
    _firestoreSub?.cancel();
    _controller.close();
  }

  // ── Internal handlers ─────────────────────────────────────────────────────
  void _onDoc(DocumentSnapshot doc) {
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    // Parse rates
    final usdtToTzs =
        (data['usdtToTzs'] as num?)?.toDouble() ?? AppRates.usdtToTzs;
    final spread = (data['spread'] as num?)?.toDouble() ?? AppRates.spread;
    final feeRate =
        (data['feeRate'] as num?)?.toDouble() ?? AppRates.exchangeFeeRate;

    final fiatRaw = data['fiat'] as Map<String, dynamic>? ?? {};
    final cryptoRaw = data['crypto'] as Map<String, dynamic>? ?? {};

    final fiat = fiatRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    final crypto = cryptoRaw.map((k, v) => MapEntry(k, (v as num).toDouble()));

    // Patch AppRates so all existing code gets live values without changes
    AppRates.applyLiveRates(
      newUsdtToTzs: usdtToTzs,
      newFiat: fiat,
      newCrypto: crypto,
      newSpread: spread,
      newFeeRate: feeRate,
    );

    final snap = RateSnapshot(
      usdtToTzs: usdtToTzs,
      spread: spread,
      feeRate: feeRate,
      fiat: fiat,
      crypto: crypto,
      updatedAt: DateTime.now(),
    );

    _latest = snap;
    _controller.add(snap);
  }

  void _onError(Object e) {
    // Silently log — fallback rates in AppRates are still used
    // ignore: avoid_print
    print('[ExchangeRateService] Firestore error: $e');
  }
}

// ── Stream extension to emit a seed value immediately ─────────────────────────
extension _StartWith<T> on Stream<T> {
  Stream<T> startWithValue(T value) async* {
    yield value;
    yield* this;
  }
}
