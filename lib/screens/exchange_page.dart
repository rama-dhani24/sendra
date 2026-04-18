import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              'Exchange',
              style: TextStyle(
                color: SColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tab bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SColors.navyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SColors.navyLight),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: SColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: SColors.navy,
                unselectedLabelColor: SColors.textSub,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Convert'),
                  Tab(text: 'FX Rates'),
                  Tab(text: 'Crypto'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Tab views ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: const [_ConverterTab(), _FxRatesTab(), _CryptoTab()],
            ),
          ),
        ],
      ),
    );
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
  // All supported currencies — fiat first, then crypto
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

  String _formatResult(double v) {
    if (v == 0) return '0';
    if (v >= 1000000) return Validators.formatDecimal(v, dp: 2);
    if (v >= 1) return Validators.formatDecimal(v, dp: 4);
    if (v >= 0.01) return v.toStringAsFixed(6);
    return v.toStringAsFixed(8); // for crypto like BTC
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_ctrl.text.trim()) ?? 0;
    final rate1 = AppRates.convert(_from, _to, 1.0);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // ── From field ───────────────────────────────────────────────────
        _CurrencyInputCard(
          label: 'You have',
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

        // ── Swap button ──────────────────────────────────────────────────
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

        // ── To field ─────────────────────────────────────────────────────
        _CurrencyOutputCard(
          label: 'You get',
          currency: _to,
          result: _result,
          formatted: _formatResult(_result),
          allCurrencies: _all,
          onCurrencyChanged: (c) => setState(() {
            _to = c;
            _calculate();
          }),
        ),
        const SizedBox(height: 20),

        // ── Rate pill ────────────────────────────────────────────────────
        if (amount > 0 && _result > 0)
          _RatePill(
            from: _from,
            to: _to,
            rate: rate1,
            formatted: _formatResult(rate1),
          ),

        const SizedBox(height: 24),

        // ── Copy result button ────────────────────────────────────────────
        if (_result > 0)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _formatResult(_result)));
                setState(() => _copied = true);
                Future.delayed(
                  const Duration(seconds: 2),
                  () => setState(() => _copied = false),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _copied ? SColors.green : SColors.navyLight,
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                color: _copied ? SColors.green : SColors.textSub,
                size: 16,
              ),
              label: Text(
                _copied ? 'Copied!' : 'Copy Result',
                style: TextStyle(
                  color: _copied ? SColors.green : SColors.textSub,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        const SizedBox(height: 28),

        // ── Quick conversions ─────────────────────────────────────────────
        _QuickConversions(from: _from, to: _to),
      ],
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // ── Rates vs TZS ──────────────────────────────────────────────────
        _SectionHeader(
          icon: '🇹🇿',
          title: 'Rates vs TZS',
          sub: '1 unit = X TZS',
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

        // ── Cross rates ───────────────────────────────────────────────────
        _SectionHeader(
          icon: '💱',
          title: 'Cross rates',
          sub: 'Mid-market, no spread',
        ),
        const SizedBox(height: 10),
        _CrossRateGrid(currencies: _fiats),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SColors.gold.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SColors.gold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: SColors.gold, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rates shown are mid-market. '
                  'A 1.5% spread applies on payments.',
                  style: SText.tiny.copyWith(color: SColors.textSub),
                ),
              ),
            ],
          ),
        ),
      ],
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
    final cryptos = AppRates.cryptoPriceUsd.keys.toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        _SectionHeader(
          icon: '🪙',
          title: 'Crypto Market',
          sub: 'Prices in USD and TZS',
        ),
        const SizedBox(height: 10),
        ...cryptos.map((symbol) {
          final usdPrice = AppRates.cryptoPriceUsd[symbol]!;
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
            color: SColors.navyCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SColors.navyLight),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: SColors.textDim,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Demo prices. Live prices via CoinGecko API in production.',
                  style: SText.tiny,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

// ── Currency input card (FROM) ─────────────────────────────────────────────
class _CurrencyInputCard extends StatelessWidget {
  final String label;
  final String currency;
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SColors.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SText.label),
          const SizedBox(height: 12),
          Row(
            children: [
              // Currency picker
              GestureDetector(
                onTap: () => _showPicker(context),
                child: _CurrencyPill(currency: currency),
              ),
              const SizedBox(width: 12),
              // Amount input
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
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: SText.hint.copyWith(fontSize: 24),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(AppRates.currencyNames[currency] ?? currency, style: SText.tiny),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
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
}

// ── Currency output card (TO) ─────────────────────────────────────────────
class _CurrencyOutputCard extends StatelessWidget {
  final String label;
  final String currency;
  final double result;
  final String formatted;
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result > 0 ? SColors.green.withOpacity(0.06) : SColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: result > 0
              ? SColors.green.withOpacity(0.3)
              : SColors.navyLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SText.label),
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
                    color: result > 0 ? SColors.green : SColors.textDim,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(AppRates.currencyNames[currency] ?? currency, style: SText.tiny),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
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
}

// ── Currency pill (flag + code) ────────────────────────────────────────────
class _CurrencyPill extends StatelessWidget {
  final String currency;
  const _CurrencyPill({required this.currency});

  @override
  Widget build(BuildContext context) {
    final flag = AppRates.currencyFlags[currency] ?? currency[0];
    final isCrypto = AppRates.isCrypto(currency);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCrypto ? SColors.gold.withOpacity(0.10) : SColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCrypto ? SColors.gold.withOpacity(0.4) : SColors.navyBorder,
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
              color: isCrypto ? SColors.gold : SColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: SColors.textDim,
            size: 16,
          ),
        ],
      ),
    );
  }
}

// ── Rate pill ──────────────────────────────────────────────────────────────
class _RatePill extends StatelessWidget {
  final String from;
  final String to;
  final double rate;
  final String formatted;

  const _RatePill({
    required this.from,
    required this.to,
    required this.rate,
    required this.formatted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SColors.navyBorder),
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
              style: const TextStyle(
                color: SColors.textSub,
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
            child: const Text(
              'Mid-market',
              style: TextStyle(
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

// ── Quick conversions grid ─────────────────────────────────────────────────
class _QuickConversions extends StatelessWidget {
  final String from;
  final String to;

  const _QuickConversions({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final amounts = AppRates.isCrypto(from)
        ? [0.001, 0.01, 0.1, 1.0, 10.0]
        : from == 'TZS'
        ? [1000.0, 5000.0, 10000.0, 50000.0, 100000.0]
        : [1.0, 10.0, 50.0, 100.0, 500.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick reference',
          style: SText.label.copyWith(letterSpacing: 0.3),
        ),
        const SizedBox(height: 10),
        ...amounts.map((a) {
          final result = AppRates.convert(from, to, a);
          String fmtA, fmtR;

          if (AppRates.isCrypto(from)) {
            fmtA = '$a $from';
          } else if (from == 'TZS') {
            fmtA = 'TZS ${Validators.formatNumber(a)}';
          } else {
            fmtA =
                '${AppRates.currencySymbols[from] ?? from} ${a.toStringAsFixed(a < 10 ? 2 : 0)}';
          }

          if (AppRates.isCrypto(to)) {
            fmtR = result >= 0.001
                ? '${result.toStringAsFixed(6)} $to'
                : '${result.toStringAsFixed(8)} $to';
          } else if (to == 'TZS') {
            fmtR = 'TZS ${Validators.formatNumber(result)}';
          } else {
            fmtR =
                '${AppRates.currencySymbols[to] ?? to} ${Validators.formatDecimal(result, dp: 4)}';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fmtA,
                    style: const TextStyle(
                      color: SColors.textSub,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: SColors.textDim,
                  size: 14,
                ),
                Expanded(
                  child: Text(
                    fmtR,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: SColors.textPrimary,
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

// ── Currency picker bottom sheet ───────────────────────────────────────────
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: SColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select Currency',
              style: TextStyle(
                color: SColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: SDecor.inputField,
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: SDecor.textInput(
                  hint: 'Search currency...',
                  prefix: const Icon(
                    Icons.search_rounded,
                    color: SColors.textDim,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List
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
                          : SColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? SColors.gold.withOpacity(0.4)
                            : SColors.navyLight,
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
                                  color: selected
                                      ? SColors.gold
                                      : SColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(name, style: SText.tiny),
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

// ── FX Rate row ────────────────────────────────────────────────────────────
class _FxRateRow extends StatelessWidget {
  final String currency;
  final String name;
  final String flag;
  final double tzs;
  final double usd;

  const _FxRateRow({
    required this.currency,
    required this.name,
    required this.flag,
    required this.tzs,
    required this.usd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SColors.navyLight),
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
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(name, style: SText.tiny),
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
                style: SText.tiny,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Cross rate grid ────────────────────────────────────────────────────────
class _CrossRateGrid extends StatelessWidget {
  final List<String> currencies;

  const _CrossRateGrid({required this.currencies});

  @override
  Widget build(BuildContext context) {
    // Show all pairs except same-currency
    final pairs = <_Pair>[];
    for (int i = 0; i < currencies.length; i++) {
      for (int j = i + 1; j < currencies.length; j++) {
        pairs.add(_Pair(currencies[i], currencies[j]));
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
            color: SColors.navyCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SColors.navyLight),
          ),
          child: Row(
            children: [
              Text(
                '${AppRates.currencyFlags[p.from] ?? ''} ${p.from}',
                style: const TextStyle(color: SColors.textSub, fontSize: 13),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: SColors.textDim,
                  size: 14,
                ),
              ),
              Text(
                '${AppRates.currencyFlags[p.to] ?? ''} ${p.to}',
                style: const TextStyle(color: SColors.textSub, fontSize: 13),
              ),
              const Spacer(),
              Text(
                fmtRate,
                style: const TextStyle(
                  color: SColors.textPrimary,
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

class _Pair {
  final String from;
  final String to;
  const _Pair(this.from, this.to);
}

// ── Crypto row ─────────────────────────────────────────────────────────────
class _CryptoRow extends StatelessWidget {
  final String symbol;
  final String name;
  final String flag;
  final double usd;
  final double tzs;

  const _CryptoRow({
    required this.symbol,
    required this.name,
    required this.flag,
    required this.usd,
    required this.tzs,
  });

  @override
  Widget build(BuildContext context) {
    final usdStr = usd >= 1
        ? '\$${Validators.formatNumber(usd)}'
        : '\$${usd.toStringAsFixed(4)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SColors.navyLight),
      ),
      child: Row(
        children: [
          // Crypto avatar
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
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(name, style: SText.tiny),
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
                style: const TextStyle(color: SColors.textSub, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: SColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(sub, style: SText.tiny),
          ],
        ),
      ],
    );
  }
}
