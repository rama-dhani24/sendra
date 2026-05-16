import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';
import 'package:sendra/services/exchange_rate_service.dart';

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return StreamBuilder<RateSnapshot>(
      stream: ExchangeRateService.instance.stream,
      builder: (context, snapshot) {
        final isLive = snapshot.hasData;
        final updatedAt = snapshot.data?.updatedAt;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    Text(
                      l.exchange,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLive
                            ? SColors.green.withOpacity(0.12)
                            : cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLive
                              ? SColors.green.withOpacity(0.3)
                              : borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isLive ? SColors.green : textDim,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isLive
                                ? (l.isSwahili ? 'Moja kwa moja' : 'Live')
                                : (l.isSwahili
                                      ? 'Inaunganisha...'
                                      : 'Connecting...'),
                            style: TextStyle(
                              color: isLive ? SColors.green : textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (updatedAt != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Text(
                    '${l.isSwahili ? 'Imesasishwa' : 'Updated'} ${_timeAgo(updatedAt, l)}',
                    style: TextStyle(color: textDim, fontSize: 11),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Tab bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: SColors.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: SColors.navy,
                    unselectedLabelColor: textSub,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: l.isSwahili ? 'Badilisha' : 'Convert'),
                      Tab(text: l.isSwahili ? 'Viwango' : 'FX Rates'),
                      Tab(text: 'Crypto'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: const [
                    _ConverterTab(),
                    _FxRatesTab(),
                    _CryptoTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt, AppLocalizations l) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return l.isSwahili ? 'sasa hivi' : 'just now';
    }
    if (diff.inMinutes < 60) {
      return l.isSwahili
          ? 'dakika ${diff.inMinutes} zilizopita'
          : '${diff.inMinutes}m ago';
    }
    return l.isSwahili
        ? 'masaa ${diff.inHours} yaliyopita'
        : '${diff.inHours}h ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1 — Converter
// ═══════════════════════════════════════════════════════════════════════════
class _ConverterTab extends StatefulWidget {
  const _ConverterTab();

  @override
  State<_ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<_ConverterTab> {
  static const _fiat = ['GBP', 'EUR', 'USD', 'USDT', 'TZS'];
  static const _crypto = ['BTC', 'ETH', 'SOL', 'BNB', 'XRP', 'ADA', 'DOGE'];
  static const _all = [..._fiat, ..._crypto];

  String _from = 'USD';
  String _to = 'TZS';
  final _ctrl = TextEditingController();
  double _result = 0;
  bool _copied = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final amount = double.tryParse(_ctrl.text.trim()) ?? 0;
    setState(() => _result = AppRates.convert(_from, _to, amount));
  }

  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
      _ctrl.clear();
      _result = 0;
    });
  }

  String _fmt(double v) {
    if (v == 0) return '0';
    if (v >= 1000000) return Validators.formatDecimal(v, dp: 2);
    if (v >= 1) return Validators.formatDecimal(v, dp: 4);
    if (v >= 0.01) return v.toStringAsFixed(6);
    return v.toStringAsFixed(8);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return StreamBuilder<RateSnapshot>(
      stream: ExchangeRateService.instance.stream,
      builder: (context, _) {
        final amount = double.tryParse(_ctrl.text.trim()) ?? 0;
        if (amount > 0) _result = AppRates.convert(_from, _to, amount);
        final rate1 = AppRates.convert(_from, _to, 1.0);

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _CurrencyInputCard(
              label: l.isSwahili ? 'Una' : 'You have',
              currency: _from,
              controller: _ctrl,
              allCurrencies: _all,
              onCurrencyChanged: (c) => setState(() {
                _from = c;
                _calculate();
              }),
              onAmountChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 12),

            Center(
              child: GestureDetector(
                onTap: _swap,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SColors.gold.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SColors.gold.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    color: SColors.gold,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _CurrencyOutputCard(
              label: l.isSwahili ? 'Unapata' : 'You get',
              currency: _to,
              result: _result,
              formatted: _fmt(_result),
              allCurrencies: _all,
              onCurrencyChanged: (c) => setState(() {
                _to = c;
                _calculate();
              }),
            ),
            const SizedBox(height: 20),

            if (amount > 0 && _result > 0)
              _RatePill(
                from: _from,
                to: _to,
                rate: rate1,
                formatted: _fmt(rate1),
              ),

            const SizedBox(height: 24),

            if (_result > 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _fmt(_result)));
                    setState(() => _copied = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _copied
                          ? SColors.green
                          : isDark
                          ? SColors.navyLight
                          : SColors.lightBorder,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    color: _copied ? SColors.green : textSub,
                    size: 16,
                  ),
                  label: Text(
                    _copied
                        ? (l.copied)
                        : (l.isSwahili ? 'Nakili Matokeo' : 'Copy Result'),
                    style: TextStyle(
                      color: _copied ? SColors.green : textSub,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 28),
            _QuickConversions(from: _from, to: _to),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2 — FX Rates
// ═══════════════════════════════════════════════════════════════════════════
class _FxRatesTab extends StatelessWidget {
  const _FxRatesTab();

  static const _fiats = ['GBP', 'EUR', 'USD', 'USDT'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return StreamBuilder<RateSnapshot>(
      stream: ExchangeRateService.instance.stream,
      builder: (context, snap) {
        final rates = snap.data;
        final spread = rates?.spread ?? AppRates.spread;
        final spreadPct = (spread * 100).toStringAsFixed(1);

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _SectionHeader(
              icon: '🇹🇿',
              title: l.isSwahili ? 'Viwango dhidi ya TZS' : 'Rates vs TZS',
              sub: l.isSwahili
                  ? '1 unit = X TZS (baada ya $spreadPct% tofauti)'
                  : '1 unit = X TZS (after $spreadPct% spread)',
            ),
            const SizedBox(height: 10),
            ..._fiats.map(
              (c) => _FxRateRow(
                currency: c,
                name: AppRates.currencyNames[c] ?? c,
                flag: AppRates.currencyFlags[c] ?? '',
                tzs: AppRates.priceInTzs(c),
                usd: AppRates.priceInUsd(c),
              ),
            ),

            const SizedBox(height: 24),
            _SectionHeader(
              icon: '💱',
              title: l.isSwahili ? 'Viwango vya msalaba' : 'Cross rates',
              sub: l.isSwahili
                  ? 'Wastani, bila tofauti'
                  : 'Mid-market, no spread',
            ),
            const SizedBox(height: 10),
            _CrossRateGrid(currencies: _fiats),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SColors.gold.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SColors.gold.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🔷', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        l.isSwahili
                            ? 'Kiwango cha USDT → TZS'
                            : 'Live USDT → TZS rate',
                        style: const TextStyle(
                          color: SColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: SColors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'CoinGecko',
                          style: TextStyle(
                            color: SColors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1 USDT = TZS ${Validators.formatNumber(AppRates.usdtToTzs)}',
                    style: const TextStyle(
                      color: SColors.gold,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: textDim, size: 12),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.isSwahili
                              ? 'Viwango vilivyoonyeshwa ni wastani. Tofauti ya $spreadPct% inatumika kwa malipo.'
                              : 'Rates shown are mid-market. A $spreadPct% spread applies on payments.',
                          style: TextStyle(color: textSub, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3 — Crypto
// ═══════════════════════════════════════════════════════════════════════════
class _CryptoTab extends StatelessWidget {
  const _CryptoTab();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return StreamBuilder<RateSnapshot>(
      stream: ExchangeRateService.instance.stream,
      builder: (context, snap) {
        final isLive = snap.hasData;
        final cryptos = AppRates.cryptoPriceUsd.keys.toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _SectionHeader(
              icon: '🪙',
              title: l.isSwahili ? 'Soko la Crypto' : 'Crypto Market',
              sub: isLive
                  ? (l.isSwahili
                        ? 'Bei za moja kwa moja kutoka CoinGecko'
                        : 'Live prices via CoinGecko')
                  : (l.isSwahili
                        ? 'Inapakia bei za moja kwa moja...'
                        : 'Loading live prices...'),
            ),
            const SizedBox(height: 10),

            if (!isLive)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: SColors.gold,
                    strokeWidth: 2,
                  ),
                ),
              ),

            if (isLive)
              ...cryptos.map((symbol) {
                final usdPrice = AppRates.cryptoPriceUsd[symbol] ?? 0;
                final tzsPrice = AppRates.convert(symbol, 'TZS', 1.0);
                return _CryptoRow(
                  symbol: symbol,
                  name: AppRates.currencyNames[symbol] ?? symbol,
                  flag: AppRates.currencyFlags[symbol] ?? symbol[0],
                  usd: usdPrice,
                  tzs: tzsPrice,
                );
              }),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    isLive
                        ? Icons.check_circle_outline
                        : Icons.schedule_rounded,
                    color: isLive ? SColors.green : textDim,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLive
                          ? (l.isSwahili
                                ? 'Bei za moja kwa moja kutoka CoinGecko · Inasasishwa kila dakika 30'
                                : 'Live prices from CoinGecko · Refreshed every 30 min')
                          : (l.isSwahili
                                ? 'Inapakia bei za moja kwa moja...'
                                : 'Fetching live prices...'),
                      style: TextStyle(color: textDim, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _CurrencyInputCard extends StatelessWidget {
  final String label, currency;
  final TextEditingController controller;
  final List<String> allCurrencies;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onAmountChanged;

  const _CurrencyInputCard({
    required this.label,
    required this.currency,
    required this.controller,
    required this.allCurrencies,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? SColors.textSub : SColors.lightTextSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showPicker(context),
                child: _CurrencyPill(currency: currency),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,8}'),
                    ),
                  ],
                  onChanged: onAmountChanged,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: textDim, fontSize: 24),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppRates.currencyNames[currency] ?? currency,
            style: TextStyle(color: textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CurrencyPickerSheet(
      selected: currency,
      allCurrencies: allCurrencies,
      onSelected: onCurrencyChanged,
    ),
  );
}

class _CurrencyOutputCard extends StatelessWidget {
  final String label, currency, formatted;
  final double result;
  final List<String> allCurrencies;
  final ValueChanged<String> onCurrencyChanged;

  const _CurrencyOutputCard({
    required this.label,
    required this.currency,
    required this.result,
    required this.formatted,
    required this.allCurrencies,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result > 0
            ? SColors.green.withOpacity(0.06)
            : (isDark ? SColors.navyCard : SColors.lightCard),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result > 0
              ? SColors.green.withOpacity(0.3)
              : (isDark ? SColors.navyLight : SColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textSub,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showPicker(context),
                child: _CurrencyPill(currency: currency),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result > 0 ? formatted : '—',
                  style: TextStyle(
                    color: result > 0 ? SColors.green : textDim,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppRates.currencyNames[currency] ?? currency,
            style: TextStyle(color: textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CurrencyPickerSheet(
      selected: currency,
      allCurrencies: allCurrencies,
      onSelected: onCurrencyChanged,
    ),
  );
}

class _CurrencyPill extends StatelessWidget {
  final String currency;
  const _CurrencyPill({required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flag = AppRates.currencyFlags[currency] ?? currency[0];
    final isCrypto = AppRates.isCrypto(currency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCrypto
            ? SColors.gold.withOpacity(0.10)
            : (isDark ? SColors.navyLight : SColors.lightBorder),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCrypto
              ? SColors.gold.withOpacity(0.4)
              : (isDark ? SColors.navyBorder : SColors.lightBorder),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isCrypto
              ? Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: SColors.gold.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      flag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: SColors.gold,
                      ),
                    ),
                  ),
                )
              : Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            currency,
            style: TextStyle(
              color: isCrypto
                  ? SColors.gold
                  : (isDark ? SColors.textPrimary : SColors.lightTextPrimary),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? SColors.textDim : SColors.lightTextDim,
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  final String from, to, formatted;
  final double rate;
  const _RatePill({
    required this.from,
    required this.to,
    required this.rate,
    required this.formatted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyBorder : SColors.lightBorder;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_flat_rounded,
            color: SColors.gold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '1 $from = $formatted $to',
              style: TextStyle(
                color: textSub,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SColors.gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              l.isSwahili ? 'Wastani' : 'Mid-market',
              style: const TextStyle(
                color: SColors.gold,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickConversions extends StatelessWidget {
  final String from, to;
  const _QuickConversions({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    final amounts = AppRates.isCrypto(from)
        ? [0.001, 0.01, 0.1, 1.0, 10.0]
        : from == 'TZS'
        ? [1000.0, 5000.0, 10000.0, 50000.0, 100000.0]
        : [1.0, 10.0, 50.0, 100.0, 500.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.isSwahili ? 'Mwongozo wa haraka' : 'Quick reference',
          style: TextStyle(
            color: textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        ...amounts.map((a) {
          final result = AppRates.convert(from, to, a);
          final fmtA = AppRates.isCrypto(from)
              ? '$a $from'
              : from == 'TZS'
              ? 'TZS ${Validators.formatNumber(a)}'
              : '${AppRates.currencySymbols[from] ?? from} ${a.toStringAsFixed(a < 10 ? 2 : 0)}';
          final fmtR = AppRates.isCrypto(to)
              ? '${result >= 0.001 ? result.toStringAsFixed(6) : result.toStringAsFixed(8)} $to'
              : to == 'TZS'
              ? 'TZS ${Validators.formatNumber(result)}'
              : '${AppRates.currencySymbols[to] ?? to} ${Validators.formatDecimal(result, dp: 4)}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fmtA,
                    style: TextStyle(color: textSub, fontSize: 13),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: textDim, size: 14),
                Expanded(
                  child: Text(
                    fmtR,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CurrencyPickerSheet extends StatefulWidget {
  final String selected;
  final List<String> allCurrencies;
  final ValueChanged<String> onSelected;
  const _CurrencyPickerSheet({
    required this.selected,
    required this.allCurrencies,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
  String _search = '';
  List<String> get _filtered => widget.allCurrencies
      .where(
        (c) =>
            c.toLowerCase().contains(_search.toLowerCase()) ||
            (AppRates.currencyNames[c] ?? '').toLowerCase().contains(
              _search.toLowerCase(),
            ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? SColors.navy : SColors.lightBg;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l.isSwahili ? 'Chagua Sarafu' : 'Select Currency',
              style: TextStyle(
                color: textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: TextStyle(color: textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: l.isSwahili
                      ? 'Tafuta sarafu...'
                      : 'Search currency...',
                  hintStyle: TextStyle(color: textDim, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search_rounded, color: textDim, size: 18),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final c = _filtered[i];
                final flag = AppRates.currencyFlags[c] ?? c[0];
                final name = AppRates.currencyNames[c] ?? c;
                final isCryp = AppRates.isCrypto(c);
                final selected = c == widget.selected;
                return GestureDetector(
                  onTap: () {
                    widget.onSelected(c);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? SColors.gold.withOpacity(0.12)
                          : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? SColors.gold.withOpacity(0.4)
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        isCryp
                            ? Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: SColors.gold.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    flag,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: SColors.gold,
                                    ),
                                  ),
                                ),
                              )
                            : Text(flag, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c,
                                style: TextStyle(
                                  color: selected ? SColors.gold : textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                name,
                                style: TextStyle(color: textDim, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: SColors.gold,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FxRateRow extends StatelessWidget {
  final String currency, name, flag;
  final double tzs, usd;
  const _FxRateRow({
    required this.currency,
    required this.name,
    required this.flag,
    required this.tzs,
    required this.usd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currency,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(name, style: TextStyle(color: textDim, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TZS ${Validators.formatNumber(tzs)}',
                style: const TextStyle(
                  color: SColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                currency == 'TZS'
                    ? ''
                    : '\$${Validators.formatDecimal(usd, dp: 4)}',
                style: TextStyle(color: textDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrossRateGrid extends StatelessWidget {
  final List<String> currencies;
  const _CrossRateGrid({required this.currencies});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    final pairs = <({String from, String to})>[];
    for (int i = 0; i < currencies.length; i++) {
      for (int j = i + 1; j < currencies.length; j++) {
        pairs.add((from: currencies[i], to: currencies[j]));
      }
    }

    return Column(
      children: pairs.map((p) {
        final rate = AppRates.convert(p.from, p.to, 1.0);
        final fmtRate = rate >= 100
            ? Validators.formatNumber(rate)
            : Validators.formatDecimal(rate, dp: 4);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Text(
                '${AppRates.currencyFlags[p.from] ?? ''} ${p.from}',
                style: TextStyle(color: textSub, fontSize: 13),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: textDim,
                  size: 14,
                ),
              ),
              Text(
                '${AppRates.currencyFlags[p.to] ?? ''} ${p.to}',
                style: TextStyle(color: textSub, fontSize: 13),
              ),
              const Spacer(),
              Text(
                fmtRate,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CryptoRow extends StatelessWidget {
  final String symbol, name, flag;
  final double usd, tzs;
  const _CryptoRow({
    required this.symbol,
    required this.name,
    required this.flag,
    required this.usd,
    required this.tzs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    final usdStr = usd >= 1
        ? '\$${Validators.formatNumber(usd)}'
        : '\$${usd.toStringAsFixed(4)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SColors.gold.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                flag,
                style: const TextStyle(
                  color: SColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(name, style: TextStyle(color: textDim, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usdStr,
                style: const TextStyle(
                  color: SColors.green,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'TZS ${Validators.formatNumber(tzs)}',
                style: TextStyle(color: textDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String icon, title, sub;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(sub, style: TextStyle(color: textDim, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
