import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
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
  // ── Step: 0 = enter acc + amount, 1 = preview, 2 = confirm PIN ──────────
  int _step = 0;

  final _accCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

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

  // ── Derived values ─────────────────────────────────────────────────────────
  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  double get _fee =>
      double.parse((_amount * AppFees.transactionFeeRate).toStringAsFixed(2));
  double get _totalDebit => _amount + _fee;

  // ── Step 0 → 1: look up receiver ──────────────────────────────────────────
  Future<void> _lookupReceiver() async {
    setState(() {
      _error = '';
    });

    final acc = _accCtrl.text.trim();
    final amount = _amount;

    if (acc.isEmpty) {
      setState(() => _error = 'Enter the recipient\'s account number.');
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
    if (_totalDebit > widget.sender.balanceTzs) {
      setState(
        () => _error =
            'Insufficient balance. You need TZS ${Validators.formatNumber(_totalDebit)} '
            '(incl. TZS ${Validators.formatNumber(_fee)} fee).',
      );
      return;
    }

    setState(() => _searching = true);

    try {
      final found = await TransactionService.findUserByAccNumber(acc);
      if (found == null) {
        setState(() {
          _error = 'No account found with number "$acc".';
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

  // ── Step 1 → 2: go to PIN confirm ─────────────────────────────────────────
  void _goToConfirm() {
    setState(() {
      _step = 2;
      _error = '';
    });
    _animCtrl
      ..reset()
      ..forward();
  }

  // ── Step 2: verify PIN and execute ────────────────────────────────────────
  Future<void> _confirmAndSend() async {
    setState(() => _error = '');

    final pin = _pinCtrl.text.trim();
    if (!Validators.isValidPin(pin)) {
      setState(() => _error = 'Enter your 4-digit PIN.');
      return;
    }

    // Verify PIN against Firestore
    setState(() => _sending = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(widget.sender.docId)
          .get();

      if (snap.data()?[FSKeys.pin] != pin) {
        setState(() {
          _error = 'Incorrect PIN. Please try again.';
          _sending = false;
        });
        return;
      }

      // ✅ FIXED: use correct parameter names matching TransactionService.sendMoney()
      final tx = await TransactionService.sendMoney(
        sender: widget.sender,
        receiver: _receiver!,
        currency: 'TZS',
        sentAmount: _amount,
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

  // ── Build ──────────────────────────────────────────────────────────────────
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

  // ── Step indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final labels = ['Recipient', 'Preview', 'Confirm'];
    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
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

  // ── Step 0: enter acc number + amount ────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sender balance hint
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

        // Recipient acc number
        Text('Recipient Account Number', style: SText.label),
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
        const SizedBox(height: 20),

        // Amount
        Text('Amount (TZS)', style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            decoration: SDecor.textInput(
              hint: '0',
              prefixText: 'TZS  ',
              prefixStyle: const TextStyle(
                color: SColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Live fee preview
        if (_amount > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SColors.navyCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fee (1%)', style: SText.caption),
                Text('Recipient gets', style: SText.caption),
                Text('Total deducted', style: SText.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TZS ${Validators.formatNumber(_fee)}',
                  style: const TextStyle(
                    color: SColors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'TZS ${Validators.formatNumber(_amount)}',
                  style: const TextStyle(
                    color: SColors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'TZS ${Validators.formatNumber(_totalDebit)}',
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 1: preview ───────────────────────────────────────────────────────
  Widget _buildStep1() {
    final r = _receiver!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Receiver card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: SDecor.balanceCard,
          child: Column(
            children: [
              // Avatar
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

        // Breakdown
        _previewRow(
          'You send',
          'TZS ${Validators.formatNumber(_amount)}',
          SColors.textPrimary,
        ),
        _divider(),
        _previewRow(
          'Transaction fee (1%)',
          'TZS ${Validators.formatNumber(_fee)}',
          SColors.red,
        ),
        _divider(),
        _previewRow(
          'Total debited',
          'TZS ${Validators.formatNumber(_totalDebit)}',
          SColors.textPrimary,
          bold: true,
        ),
        _divider(),
        _previewRow(
          'Recipient gets',
          'TZS ${Validators.formatNumber(_amount)}',
          SColors.green,
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
          Text(label, style: SText.caption),
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
            'Enter your PIN to send\n'
            'TZS ${Validators.formatNumber(_amount)} to ${_receiver!.fullName}',
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
    final label = _step == 0
        ? 'Find Recipient'
        : _step == 1
        ? 'Proceed to Confirm'
        : 'Send TZS ${Validators.formatNumber(_amount)}';
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
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}

// ─── Error box ─────────────────────────────────────────────────────────────
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
