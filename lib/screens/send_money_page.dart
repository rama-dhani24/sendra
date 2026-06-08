import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';
import 'package:sendra/screens/transaction_service.dart';
import 'package:sendra/services/exchange_rate_service.dart';
import 'package:sendra/screens/receipt_screen.dart';

class SendMoneyPage extends StatefulWidget {
  final UserLookup sender;
  const SendMoneyPage({super.key, required this.sender});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0=details, 1=preview, 2=PIN

  final _accCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  static const _currencies = ['GBP', 'EUR', 'USD', 'USDT'];
  static const _flags = {
    'GBP': '🇬🇧',
    'EUR': '🇪🇺',
    'USD': '🇺🇸',
    'USDT': '🔷',
  };
  static const _symbols = {'GBP': '£', 'EUR': '€', 'USD': '\$', 'USDT': '₮'};

  String _currency = 'GBP';
  bool _searching = false;
  bool _sending = false;
  bool _pinHidden = true;
  String _error = '';
  UserLookup? _receiver;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _accCtrl.dispose();
    _amountCtrl.dispose();
    _pinCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Live derived values ───────────────────────────────────────────────────
  double get _sent => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  double get _tzsReceived {
    if (_sent <= 0) return 0;
    final r = ExchangeRateService.instance.latest;
    return r != null
        ? r.toTzs(_currency, _sent)
        : AppRates.toTzs(_currency, _sent);
  }

  double get _usdtAmt {
    if (_sent <= 0) return 0;
    final r = ExchangeRateService.instance.latest;
    final spread = r?.spread ?? AppRates.spread;
    final u2t = r?.usdtToTzs ?? AppRates.usdtToTzs;
    if (_currency == 'TZS') return _sent / u2t;
    if (_currency == 'USDT') return _sent * (1 - spread);
    double fr;
    if (r != null && r.fiat.containsKey(_currency)) {
      fr = r.fiat[_currency]!;
    } else {
      switch (_currency) {
        case 'GBP':
          fr = AppRates.gbpToUsdt;
          break;
        case 'EUR':
          fr = AppRates.eurToUsdt;
          break;
        default:
          fr = AppRates.usdToUsdt;
      }
    }
    return _sent * fr * (1 - spread);
  }

  double get _feeTzs => double.parse(
    (_tzsReceived * AppFees.transactionFeeRate).toStringAsFixed(2),
  );

  double get _totalDebit => _tzsReceived + _feeTzs;

  double get _spreadPct {
    final r = ExchangeRateService.instance.latest;
    return (r?.spread ?? AppRates.spread) * 100;
  }

  String _rateLabel(AppLocalizations l) {
    final r = ExchangeRateService.instance.latest;
    final tzs = r != null
        ? r.toTzs(_currency, 1.0)
        : AppRates.toTzs(_currency, 1.0);
    return '1 $_currency ≈ TZS ${Validators.formatNumber(tzs)} '
        '(${_spreadPct.toStringAsFixed(1)}% ${l.isSwahili ? 'tofauti' : 'spread'})';
  }

  // ── Step 0 → 1: find receiver ─────────────────────────────────────────────
  Future<void> _lookupReceiver(AppLocalizations l) async {
    setState(() => _error = '');
    final acc = _accCtrl.text.trim();

    if (acc.isEmpty) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka Sendra ID ya mpokeaji.'
            : 'Enter the recipient\'s Sendra ID.',
      );
      return;
    }
    if (acc == widget.sender.accNumber) {
      setState(
        () => _error = l.isSwahili
            ? 'Hauwezi kutuma kwa mwenyewe.'
            : 'Cannot send to yourself.',
      );
      return;
    }
    if (_sent <= 0) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka kiasi sahihi.'
            : 'Enter a valid amount.',
      );
      return;
    }
    if (_totalDebit > widget.sender.balanceTzs) {
      setState(
        () => _error = l.isSwahili
            ? 'Salio haitoshi. Unahitaji TZS ${Validators.formatNumber(_totalDebit)} (pamoja na ada).'
            : 'Insufficient balance. Need TZS ${Validators.formatNumber(_totalDebit)} (incl. fee).',
      );
      return;
    }

    setState(() => _searching = true);
    try {
      final found = await TransactionService.findUserByAccNumber(acc);
      if (found == null) {
        setState(() {
          _error = l.isSwahili
              ? 'Akaunti yenye ID "$acc" haikupatikana.'
              : 'No account found with ID "$acc".';
          _searching = false;
        });
        return;
      }
      setState(() {
        _receiver = found;
        _step = 1;
        _searching = false;
      });
      _animCtrl
        ..reset()
        ..forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _searching = false;
      });
    }
  }

  // ── Step 1 → 2 ────────────────────────────────────────────────────────────
  void _goToPin() {
    setState(() {
      _step = 2;
      _error = '';
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Step 2: verify PIN then execute ──────────────────────────────────────
  Future<void> _confirmAndSend(AppLocalizations l) async {
    setState(() => _error = '');
    final pin = _pinCtrl.text.trim();
    if (!Validators.isValidPin(pin)) {
      setState(() => _error = l.pinMust4Digits);
      return;
    }

    setState(() => _sending = true);

    try {
      final userSnap = await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(widget.sender.docId)
          .get();

      if (!userSnap.exists) {
        setState(() {
          _error = l.isSwahili
              ? 'Akaunti haikupatikana. Tafadhali ingia tena.'
              : 'Account not found. Please log in again.';
          _sending = false;
        });
        return;
      }

      final storedPin = (userSnap.data()![FSKeys.pin] ?? '').toString().trim();

      if (storedPin != pin) {
        setState(() {
          _error = l.incorrectPin;
          _sending = false;
        });
        return;
      }

      final tx = await TransactionService.sendMoney(
        sender: widget.sender,
        receiver: _receiver!,
        currency: _currency,
        sentAmount: _sent,
      );

      if (!mounted) return;
      setState(() => _sending = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReceiptScreen(transaction: tx)),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _sending = false;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    final stepTitles = [
      l.sendMoney,
      l.isSwahili ? 'Thibitisha Maelezo' : 'Confirm Details',
      l.isSwahili ? 'Weka PIN' : 'Enter PIN',
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textSub, size: 18),
          onPressed: () {
            if (_step == 0) {
              Navigator.of(context).pop();
              return;
            }
            setState(() {
              _step--;
              _error = '';
              if (_step == 0) _pinCtrl.clear();
            });
            _animCtrl
              ..reset()
              ..forward();
          },
        ),
        title: Text(
          stepTitles[_step],
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepBar(isDark),
                const SizedBox(height: 28),
                if (_step == 0) _buildStep0(l, isDark),
                if (_step == 1) _buildStep1(l, isDark),
                if (_step == 2) _buildStep2(l, isDark),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ErrorBox(message: _error),
                ],
                const SizedBox(height: 28),
                _buildButton(l, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step progress bar ─────────────────────────────────────────────────────
  Widget _buildStepBar(bool isDark) {
    final inactiveColor = isDark ? SColors.navyCard : SColors.lightCard;
    final inactiveBorder = isDark ? SColors.navyLight : SColors.lightBorder;
    final inactiveLineColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: _step >= (i ~/ 2) + 1 ? SColors.gold : inactiveLineColor,
            ),
          );
        }
        final idx = i ~/ 2;
        final active = _step >= idx;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? SColors.gold : inactiveColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? SColors.gold : inactiveBorder,
              width: 2,
            ),
          ),
          child: Center(
            child: _step > idx
                ? const Icon(Icons.check, color: SColors.navy, size: 14)
                : Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: active ? SColors.navy : textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  // ── Step 0: details ───────────────────────────────────────────────────────
  Widget _buildStep0(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final symbol = _symbols[_currency] ?? _currency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: SColors.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.availableBalance,
                    style: TextStyle(color: textDim, fontSize: 11),
                  ),
                  Text(
                    'TZS ${Validators.formatNumber(widget.sender.balanceTzs)}',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Currency selector
        Text(
          l.sendingCurrency,
          style: TextStyle(
            color: textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _currencies.map((c) {
            final sel = c == _currency;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currency = c),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? SColors.gold.withOpacity(0.15) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? SColors.gold : borderColor,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _flags[c] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c,
                        style: TextStyle(
                          color: sel ? SColors.gold : textSub,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(_rateLabel(l), style: TextStyle(color: textDim, fontSize: 11)),
        const SizedBox(height: 20),

        // Amount field
        Text(
          '${l.amount} ($symbol)',
          style: TextStyle(
            color: textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,6}')),
            ],
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(color: textDim, fontSize: 22),
              prefixText: '$symbol  ',
              prefixStyle: const TextStyle(
                color: SColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Live conversion breakdown
        if (_sent > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.swap_vert_rounded,
                      color: SColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.isSwahili
                          ? 'Ubadilishaji wa moja kwa moja'
                          : 'Live conversion',
                      style: TextStyle(color: textDim, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_currency != 'USDT') ...[
                  _convRow(
                    '$_currency → USDT',
                    '≈ ${Validators.formatUsdt(_usdtAmt)} USDT',
                    textSub,
                    textSub,
                  ),
                  const SizedBox(height: 6),
                ],
                _convRow(
                  'USDT → TZS',
                  'TZS ${Validators.formatNumber(_tzsReceived)}',
                  textSub,
                  SColors.green,
                ),
                Divider(color: borderColor, height: 20),
                _convRow(
                  l.transactionFee,
                  '− TZS ${Validators.formatNumber(_feeTzs)}',
                  textSub,
                  SColors.red,
                ),
                Divider(color: borderColor, height: 20),
                _convRow(
                  l.recipientGets,
                  'TZS ${Validators.formatNumber(_tzsReceived)}',
                  textSub,
                  SColors.green,
                  bold: true,
                ),
                _convRow(
                  l.totalDeducted,
                  'TZS ${Validators.formatNumber(_totalDebit)}',
                  textSub,
                  textPrimary,
                  bold: true,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Recipient ID field
        Text(
          l.recipientId,
          style: TextStyle(
            color: textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _accCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '00000',
              hintStyle: TextStyle(color: textDim, fontSize: 20),
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.tag_rounded, color: textDim, size: 18),
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
        const SizedBox(height: 6),
        Text(
          l.isSwahili
              ? 'Sendra ID ya tarakimu 5 ya mpokeaji'
              : '5-digit Sendra ID of the recipient',
          style: TextStyle(color: textDim, fontSize: 11),
        ),
      ],
    );
  }

  Widget _convRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool bold = false,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
      Text(
        value,
        style: TextStyle(
          color: valueColor,
          fontSize: bold ? 14 : 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    ],
  );

  // ── Step 1: preview ───────────────────────────────────────────────────────
  Widget _buildStep1(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    final r = _receiver!;
    final symbol = _symbols[_currency] ?? _currency;
    final flag = _flags[_currency] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipient card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SColors.gold, SColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    _initials(r.fullName),
                    style: const TextStyle(
                      color: SColors.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                r.fullName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${l.sendraId}: ${r.accNumber}',
                style: const TextStyle(color: SColors.gold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Transaction breakdown rows
        _pRow(
          l.isSwahili ? 'Unatuma' : 'You send',
          '$flag $symbol ${_sent.toStringAsFixed(4)} $_currency',
          textSub,
          textPrimary,
        ),
        _div(borderColor),

        if (_currency != 'USDT') ...[
          _pRow(
            l.isSwahili ? 'Imebadilishwa hadi USDT' : 'Converted to USDT',
            '≈ ${Validators.formatUsdt(_usdtAmt)} USDT',
            textSub,
            textSub,
          ),
          _div(borderColor),
        ],

        _pRow(
          l.isSwahili ? 'Imebadilishwa hadi TZS' : 'Converted to TZS',
          'TZS ${Validators.formatNumber(_tzsReceived)}',
          textSub,
          textPrimary,
        ),
        _div(borderColor),

        _pRow(
          l.isSwahili ? 'Tofauti' : 'Spread',
          '${_spreadPct.toStringAsFixed(1)}%',
          textSub,
          textSub,
        ),
        _div(borderColor),

        _pRow(
          l.transactionFee,
          '− TZS ${Validators.formatNumber(_feeTzs)}',
          textSub,
          SColors.red,
        ),
        _div(borderColor),

        _pRow(
          l.recipientGets,
          'TZS ${Validators.formatNumber(_tzsReceived)}',
          textSub,
          SColors.green,
          bold: true,
        ),
        _div(borderColor),

        _pRow(
          l.totalDeducted,
          'TZS ${Validators.formatNumber(_totalDebit)}',
          textSub,
          textPrimary,
          bold: true,
        ),

        const SizedBox(height: 20),

        // Warning banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SColors.gold.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SColors.gold.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: SColors.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.irreversibleWarn,
                  style: TextStyle(color: textSub, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor, {
    bool bold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _div(Color color) => Container(height: 1, color: color);

  // ── Step 2: PIN ───────────────────────────────────────────────────────────
  Widget _buildStep2(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SColors.gold.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: SColors.gold,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            l.authorizeTransaction,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            l.isSwahili
                ? 'Unatuma ${_symbols[_currency] ?? ''} ${_sent.toStringAsFixed(2)} $_currency\n'
                      '→ TZS ${Validators.formatNumber(_tzsReceived)} kwa ${_receiver!.fullName}'
                : 'Sending ${_symbols[_currency] ?? ''} ${_sent.toStringAsFixed(2)} $_currency\n'
                      '→ TZS ${Validators.formatNumber(_tzsReceived)} to ${_receiver!.fullName}',
            style: TextStyle(color: textSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),

        Text(
          l.isSwahili ? 'PIN yako' : 'Your PIN',
          style: TextStyle(
            color: textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _pinCtrl,
            obscureText: _pinHidden,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            autofocus: true,
            onSubmitted: (_) => _confirmAndSend(l),
            style: TextStyle(
              color: textPrimary,
              fontSize: 28,
              letterSpacing: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '••••',
              hintStyle: TextStyle(color: textDim, fontSize: 15),
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _pinHidden = !_pinHidden),
                  child: Icon(
                    _pinHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textDim,
                    size: 18,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
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
      ],
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────
  Widget _buildButton(AppLocalizations l, bool isDark) {
    final loading = _searching || _sending;
    final symbol = _symbols[_currency] ?? _currency;

    final labels = [
      l.findRecipient,
      l.proceedConfirm,
      l.isSwahili
          ? 'Tuma $symbol ${_sent.toStringAsFixed(2)} → TZS'
          : 'Send $symbol ${_sent.toStringAsFixed(2)} → TZS',
    ];

    final actions = [
      () => _lookupReceiver(l),
      _goToPin,
      () => _confirmAndSend(l),
    ];

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : actions[_step],
        style: SButton.primary,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: SColors.navy,
                  strokeWidth: 2.5,
                ),
              )
            : Text(labels[_step], style: SButton.primaryLabel),
      ),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) {
      return '${p.first[0]}${p.last[0]}'.toUpperCase();
    }
    return p.first.isNotEmpty ? p.first[0].toUpperCase() : '?';
  }
}

// ─── Error box ────────────────────────────────────────────────────────────────
class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: SDecor.errorBox,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: SColors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: SText.errorText)),
        ],
      ),
    );
  }
}
