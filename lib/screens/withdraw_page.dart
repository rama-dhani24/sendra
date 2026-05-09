import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

class WithdrawPage extends StatefulWidget {
  final String userId;
  final double balanceTzs;
  const WithdrawPage({
    super.key,
    required this.userId,
    required this.balanceTzs,
  });

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _method = 'M-Pesa';
  bool _loading = false;
  String _error = '';

  static const _methods = ['M-Pesa', 'Tigo Pesa', 'Airtel Money', 'Halotel'];
  static const _methodIcons = {
    'M-Pesa': '🟢',
    'Tigo Pesa': '🔵',
    'Airtel Money': '🔴',
    'Halotel': '🟠',
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  double get _fee => double.parse((_amount * 0.01).toStringAsFixed(2));
  double get _total => _amount + _fee;

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Withdraw',
          style: TextStyle(
            color: SColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: SDecor.card,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: SColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: SColors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Available Balance', style: SText.tiny),
                        Text(
                          'TZS ${Validators.formatNumber(widget.balanceTzs)}',
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

              // Method selector
              Text('Withdrawal Method', style: SText.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _methods.map((m) {
                  final sel = m == _method;
                  return GestureDetector(
                    onTap: () => setState(() => _method = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? SColors.gold.withOpacity(0.15)
                            : SColors.navyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? SColors.gold : SColors.navyLight,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _methodIcons[m] ?? '',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m,
                            style: TextStyle(
                              color: sel ? SColors.gold : SColors.textSub,
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Phone
              Text('Mobile Number', style: SText.label),
              const SizedBox(height: 8),
              Container(
                decoration: SDecor.inputField,
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: SText.body,
                  decoration: SDecor.textInput(
                    hint: '07XXXXXXXX',
                    prefix: const Icon(
                      Icons.phone_outlined,
                      color: SColors.textDim,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Amount
              Text('Amount (TZS)', style: SText.label),
              const SizedBox(height: 8),
              Container(
                decoration: SDecor.inputField,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
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

              if (_amount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: SColors.navyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SColors.navyLight),
                  ),
                  child: Column(
                    children: [
                      _row(
                        'Withdrawal amount',
                        'TZS ${Validators.formatNumber(_amount)}',
                        SColors.textPrimary,
                      ),
                      const SizedBox(height: 6),
                      _row(
                        'Fee (1%)',
                        '- TZS ${Validators.formatNumber(_fee)}',
                        SColors.red,
                      ),
                      const Divider(color: SColors.navyLight, height: 16),
                      _row(
                        'You receive',
                        'TZS ${Validators.formatNumber(_amount - _fee)}',
                        SColors.green,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: SDecor.errorBox,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: SColors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error, style: SText.errorText)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: SButton.primary,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: SColors.navy,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Withdraw Now', style: SButton.primaryLabel),
                ),
              ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SColors.gold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: SColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Withdrawals are processed within 1-5 minutes. Available 24/7.',
                        style: SText.tiny.copyWith(color: SColors.textSub),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v, Color vc, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: SText.caption),
      Text(
        v,
        style: TextStyle(
          color: vc,
          fontSize: bold ? 14 : 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    ],
  );

  void _submit() {
    setState(() => _error = '');
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || !Validators.isValidTZPhone(phone)) {
      setState(() => _error = 'Enter a valid Tanzanian phone number.');
      return;
    }
    if (_amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (_total > widget.balanceTzs) {
      setState(() => _error = 'Insufficient balance.');
      return;
    }

    // Show coming soon for MVP
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: SColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Coming Soon',
          style: TextStyle(
            color: SColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Mobile money withdrawals will be available in the next release.',
          style: SText.caption,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: SColors.gold)),
          ),
        ],
      ),
    );
  }
}
