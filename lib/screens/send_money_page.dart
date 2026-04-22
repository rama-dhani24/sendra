import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/services/exchange_rate_service.dart';
import 'package:sendra/services/transaction_service.dart';
import 'package:sendra/screens/receipt_screen.dart';

class SendMoneyPage extends StatefulWidget {
  final UserLookup sender;
  const SendMoneyPage({super.key, required this.sender});

  @override
  State<SendMoneyPage> createState() => _SendMoneyPageState();
}

class _SendMoneyPageState extends State<SendMoneyPage>
    with SingleTickerProviderStateMixin {
  // ── Step: 0 = enter details, 1 = preview, 2 = confirm PIN ───────────────
  int _step = 0;

  final _accCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  // Sending currencies per the plan
  static const _currencies = ['GBP', 'EUR', 'USD', 'USDT'];
  static const _currencyFlags = {
    'GBP': '🇬🇧',
    'EUR': '🇪🇺',
    'USD': '🇺🇸',
    'USDT': '🔷',
  };
  static const _currencySymbols = {
    'GBP': '£',
    'EUR': '€',
    'USD': '\$',
    'USDT': '₮',
  };

  String _selectedCurrency = 'GBP'; // default sending currency

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

  // ── Derived conversion values (live) ──────────────────────────────────────
  double get _sentAmount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  // How much TZS the receiver gets (after spread, before fee)
  double get _tzsReceived {
    if (_sentAmount <= 0) return 0;
    final rates = ExchangeRateService.instance.latest;
    if (rates != null) return rates.toTzs(_selectedCurrency, _sentAmount);
    return AppRates.toTzs(_selectedCurrency, _sentAmount);
  }

  // USDT equivalent (for display and storage)
  double get _usdtAmount {
    if (_sentAmount <= 0) return 0;
    final rates = ExchangeRateService.instance.latest;
    final spread = rates?.spread ?? AppRates.spread;
    final usdtToTzs = rates?.usdtToTzs ?? AppRates.usdtToTzs;
    if (_selectedCurrency == 'TZS') return _sentAmount / usdtToTzs;
    if (_selectedCurrency == 'USDT') return _sentAmount * (1 - spread);
    double fiatRate;
    if (rates != null && rates.fiat.containsKey(_selectedCurrency)) {
      fiatRate = rates.fiat[_selectedCurrency]!;
    } else {
      switch (_selectedCurrency) {
        case 'GBP':
          fiatRate = AppRates.gbpToUsdt;
          break;
        case 'EUR':
          fiatRate = AppRates.eurToUsdt;
          break;
        default:
          fiatRate = AppRates.usdToUsdt;
      }
    }
    return _sentAmount * fiatRate * (1 - spread);
  }

  // Fee is 1% of TZS amount
  double get _feeTzs => double.parse(
    (_tzsReceived * AppFees.transactionFeeRate).toStringAsFixed(2),
  );

  // Total TZS debited from sender's TZS balance
  double get _totalDebitTzs => _tzsReceived + _feeTzs;

  // Spread % for display
  double get _spreadPct {
    final rates = ExchangeRateService.instance.latest;
    return (rates?.spread ?? AppRates.spread) * 100;
  }

  // Live rate label
  String get _rateLabel {
    final rates = ExchangeRateService.instance.latest;
    final tzs = rates != null
        ? rates.toTzs(_selectedCurrency, 1.0)
        : AppRates.toTzs(_selectedCurrency, 1.0);
    return '1 $_selectedCurrency ≈ TZS ${Validators.formatNumber(tzs)} '
        '(${_spreadPct.toStringAsFixed(1)}% spread applied)';
  }

  // ── Step 0 → 1: look up receiver ─────────────────────────────────────────
  Future<void> _lookupReceiver() async {
    setState(() => _error = '');

    final acc = _accCtrl.text.trim();
    final amount = _sentAmount;

    if (acc.isEmpty) {
      setState(() => _error = 'Enter the recipient\'s Sendra ID.');
      return;
    }
    if (acc == widget.sender.accNumber) {
      setState(() => _error = 'You cannot send money to yourself.');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (_totalDebitTzs > widget.sender.balanceTzs) {
      setState(
        () => _error =
            'Insufficient TZS balance. You need TZS ${Validators.formatNumber(_totalDebitTzs)} '
            '(incl. TZS ${Validators.formatNumber(_feeTzs)} fee).',
      );
      return;
    }

    setState(() => _searching = true);

    try {
      final found = await TransactionService.findUserByAccNumber(acc);
      if (found == null) {
        setState(() {
          _error = 'No account found with ID "$acc".';
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
    } catch (_) {
      setState(() {
        _error = 'Network error. Please try again.';
        _searching = false;
      });
    }
  }

  // ── Step 1 → 2 ───────────────────────────────────────────────────────────
  void _goToConfirm() {
    setState(() {
      _step = 2;
      _error = '';
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Step 2: verify PIN via Firebase Auth + execute ────────────────────────
  Future<void> _confirmAndSend() async {
    setState(() => _error = '');

    final pin = _pinCtrl.text.trim();
    if (!Validators.isValidPin(pin)) {
      setState(() => _error = 'Enter your 4-digit PIN.');
      return;
    }

    setState(() => _sending = true);

    try {
      // Re-authenticate with Firebase Auth to verify PIN
      // This is more secure than reading the PIN from Firestore
      final user = FirebaseAuth.instance.currentUser;
      final phone = widget.sender.phone;
      final email = '$phone@sendra.app';

      if (user == null) throw 'Session expired. Please log in again.';

      try {
        final credential = EmailAuthProvider.credential(
          email: email,
          password: '${pin}_sendra',
        );
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException {
        setState(() {
          _error = 'Incorrect PIN. Please try again.';
          _sending = false;
        });
        return;
      }

      // PIN verified — execute the transaction
      final tx = await TransactionService.sendMoney(
        sender: widget.sender,
        receiver: _receiver!,
        currency: _selectedCurrency,
        sentAmount: _sentAmount,
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
    return Scaffold(
      backgroundColor: SColors.bg,
      appBar: AppBar(
        backgroundColor: SColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: SColors.textSub,
            size: 18,
          ),
          onPressed: () {
            if (_step == 0) {
              Navigator.of(context).pop();
            } else {
              setState(() {
                _step = _step - 1;
                _error = '';
                if (_step == 0) _pinCtrl.clear();
              });
              _animCtrl
                ..reset()
                ..forward();
            }
          },
        ),
        title: Text(
          _step == 0
              ? 'Send Money'
              : _step == 1
              ? 'Confirm Details'
              : 'Enter PIN',
          style: SText.sectionTitle,
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
                _buildStepIndicator(),
                const SizedBox(height: 28),
                if (_step == 0) _buildStep0(),
                if (_step == 1) _buildStep1(),
                if (_step == 2) _buildStep2(),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _ErrorBox(message: _error),
                ],
                const SizedBox(height: 28),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: _step >= (i ~/ 2) + 1 ? SColors.gold : SColors.navyLight,
            ),
          );
        }
        final idx = i ~/ 2;
        final active = _step >= idx;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: active ? SColors.gold : SColors.navyCard,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? SColors.gold : SColors.navyLight,
              width: 2,
            ),
          ),
          child: Center(
            child: _step > idx
                ? const Icon(Icons.check, color: SColors.navy, size: 14)
                : Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: active ? SColors.navy : SColors.textDim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  // ── Step 0: currency + amount + recipient ─────────────────────────────────
  Widget _buildStep0() {
    final symbol = _currencySymbols[_selectedCurrency] ?? _selectedCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sender TZS balance
        Container(
          padding: const EdgeInsets.all(14),
          decoration: SDecor.card,
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
                  Text('Available Balance', style: SText.tiny),
                  Text(
                    'TZS ${Validators.formatNumber(widget.sender.balanceTzs)}',
                    style: const TextStyle(
                      color: SColors.textPrimary,
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

        // ── Currency selector ─────────────────────────────────────────────
        Text('Sending Currency', style: SText.label),
        const SizedBox(height: 10),
        Row(
          children: _currencies.map((c) {
            final selected = c == _selectedCurrency;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _selectedCurrency = c;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? SColors.gold.withOpacity(0.15)
                        : SColors.navyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? SColors.gold : SColors.navyLight,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _currencyFlags[c] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c,
                        style: TextStyle(
                          color: selected ? SColors.gold : SColors.textSub,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
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
        // Live rate for selected currency
        Text(_rateLabel, style: SText.tiny),
        const SizedBox(height: 20),

        // ── Amount input ──────────────────────────────────────────────────
        Text('Amount ($symbol)', style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,6}')),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: SDecor.textInput(
              hint: '0',
              prefixText: '$symbol  ',
              prefixStyle: const TextStyle(
                color: SColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // ── Live conversion preview ───────────────────────────────────────
        if (_sentAmount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SColors.navyLight),
            ),
            child: Column(
              children: [
                // Conversion path
                Row(
                  children: [
                    const Icon(
                      Icons.arrow_downward_rounded,
                      color: SColors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text('Conversion breakdown', style: SText.tiny),
                  ],
                ),
                const SizedBox(height: 10),
                if (_selectedCurrency != 'USDT') ...[
                  _convRow(
                    '$_selectedCurrency → USDT',
                    '≈ ${Validators.formatUsdt(_usdtAmount)} USDT',
                    SColors.textSub,
                  ),
                  const SizedBox(height: 6),
                ],
                _convRow(
                  'USDT → TZS',
                  'TZS ${Validators.formatNumber(_tzsReceived)}',
                  SColors.green,
                ),
                const Divider(color: SColors.navyLight, height: 20),
                _convRow(
                  'Fee (1%)',
                  '− TZS ${Validators.formatNumber(_feeTzs)}',
                  SColors.red,
                ),
                const Divider(color: SColors.navyLight, height: 20),
                _convRow(
                  'Recipient gets',
                  'TZS ${Validators.formatNumber(_tzsReceived)}',
                  SColors.green,
                  bold: true,
                ),
                _convRow(
                  'Total deducted',
                  'TZS ${Validators.formatNumber(_totalDebitTzs)}',
                  SColors.textPrimary,
                  bold: true,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── Recipient account ─────────────────────────────────────────────
        Text('Recipient Sendra ID', style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: TextField(
            controller: _accCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
            decoration: SDecor.textInput(
              hint: '00000',
              prefix: const Icon(
                Icons.tag_rounded,
                color: SColors.textDim,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('5-digit Sendra ID of the recipient', style: SText.tiny),
      ],
    );
  }

  Widget _convRow(
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: SText.caption),
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
  }

  // ── Step 1: preview ───────────────────────────────────────────────────────
  Widget _buildStep1() {
    final r = _receiver!;
    final symbol = _currencySymbols[_selectedCurrency] ?? _selectedCurrency;
    final flag = _currencyFlags[_selectedCurrency] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Receiver card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: SDecor.balanceCard,
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
                style: const TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sendra ID: ${r.accNumber}',
                style: const TextStyle(color: SColors.gold, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Full breakdown matching the plan
        _previewRow(
          'You send',
          '$flag $symbol ${_sentAmount.toStringAsFixed(_selectedCurrency == 'USDT' ? 2 : 4)} $_selectedCurrency',
          SColors.textPrimary,
        ),
        _divider(),
        if (_selectedCurrency != 'USDT') ...[
          _previewRow(
            'Converted to USDT',
            '≈ ${Validators.formatUsdt(_usdtAmount)} USDT',
            SColors.textSub,
          ),
          _divider(),
        ],
        _previewRow(
          'Converted to TZS',
          'TZS ${Validators.formatNumber(_tzsReceived)}',
          SColors.textPrimary,
        ),
        _divider(),
        _previewRow(
          'Spread applied',
          '${_spreadPct.toStringAsFixed(1)}%',
          SColors.textSub,
        ),
        _divider(),
        _previewRow(
          'Transaction fee (1%)',
          '− TZS ${Validators.formatNumber(_feeTzs)}',
          SColors.red,
        ),
        _divider(),
        _previewRow(
          'Recipient gets',
          'TZS ${Validators.formatNumber(_tzsReceived)}',
          SColors.green,
          bold: true,
        ),
        _divider(),
        _previewRow(
          'Total debited from your balance',
          'TZS ${Validators.formatNumber(_totalDebitTzs)}',
          SColors.textPrimary,
          bold: true,
        ),

        const SizedBox(height: 20),
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
                  'Review carefully. This transaction cannot be reversed.',
                  style: SText.tiny.copyWith(color: SColors.textSub),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewRow(
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: SText.caption)),
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
  }

  Widget _divider() => Container(height: 1, color: SColors.navyLight);

  // ── Step 2: PIN entry ─────────────────────────────────────────────────────
  Widget _buildStep2() {
    final symbol = _currencySymbols[_selectedCurrency] ?? _selectedCurrency;
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
        Center(child: Text('Authorize Transaction', style: SText.title)),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Sending $_selectedCurrency ${_sentAmount.toStringAsFixed(2)}\n'
            '→ TZS ${Validators.formatNumber(_tzsReceived)} to ${_receiver!.fullName}',
            style: SText.caption,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),
        Text('Your PIN', style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: TextField(
            controller: _pinCtrl,
            obscureText: _pinHidden,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            autofocus: true,
            onSubmitted: (_) => _confirmAndSend(),
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 28,
              letterSpacing: 14,
              fontWeight: FontWeight.w700,
            ),
            decoration: SDecor.textInput(
              hint: '••••',
              suffix: GestureDetector(
                onTap: () => setState(() => _pinHidden = !_pinHidden),
                child: Icon(
                  _pinHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SColors.textDim,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Action button ─────────────────────────────────────────────────────────
  Widget _buildActionButton() {
    final loading = _searching || _sending;
    final symbol = _currencySymbols[_selectedCurrency] ?? _selectedCurrency;
    final label = _step == 0
        ? 'Find Recipient'
        : _step == 1
        ? 'Proceed to Confirm'
        : 'Send $symbol ${_sentAmount.toStringAsFixed(2)} → TZS';
    final onTap = _step == 0
        ? _lookupReceiver
        : _step == 1
        ? _goToConfirm
        : _confirmAndSend;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
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
            : Text(label, style: SButton.primaryLabel),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}

// ─── Error box ───────────────────────────────────────────────────────────────
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
