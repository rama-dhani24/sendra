import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

class BankTransferPage extends StatefulWidget {
  final String userId;
  final double balanceTzs;
  const BankTransferPage({
    super.key,
    required this.userId,
    required this.balanceTzs,
  });

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage> {
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _bank = 'CRDB Bank';
  String _error = '';

  static const _banks = [
    'CRDB Bank',
    'NMB Bank',
    'NBC Bank',
    'Stanbic Bank',
    'Equity Bank',
    'DTB Bank',
  ];
  static const _bankFlags = {
    'CRDB Bank': '🏦',
    'NMB Bank': '🏛️',
    'NBC Bank': '🏢',
    'Stanbic Bank': '🏗️',
    'Equity Bank': '💼',
    'DTB Bank': '🏬',
  };

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  double get _fee => 2000; // flat fee for bank transfers

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
          'Bank Transfer',
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
              Container(
                padding: const EdgeInsets.all(16),
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
                        Icons.account_balance_outlined,
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

              Text('Select Bank', style: SText.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _banks.map((b) {
                  final sel = b == _bank;
                  return GestureDetector(
                    onTap: () => setState(() => _bank = b),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? SColors.gold.withOpacity(0.15)
                            : SColors.navyCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? SColors.gold : SColors.navyLight,
                          width: sel ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _bankFlags[b] ?? '🏦',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            b,
                            style: TextStyle(
                              color: sel ? SColors.gold : SColors.textSub,
                              fontSize: 12,
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

              Text('Account Number', style: SText.label),
              const SizedBox(height: 8),
              Container(
                decoration: SDecor.inputField,
                child: TextField(
                  controller: _accountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  style: SText.body,
                  decoration: SDecor.textInput(
                    hint: 'Enter account number',
                    prefix: const Icon(
                      Icons.credit_card_outlined,
                      color: SColors.textDim,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Account Name', style: SText.label),
              const SizedBox(height: 8),
              Container(
                decoration: SDecor.inputField,
                child: TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: SText.body,
                  decoration: SDecor.textInput(
                    hint: 'Account holder name',
                    prefix: const Icon(
                      Icons.person_outline,
                      color: SColors.textDim,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        'Transfer amount',
                        'TZS ${Validators.formatNumber(_amount)}',
                        SColors.textPrimary,
                      ),
                      const SizedBox(height: 6),
                      _row(
                        'Bank fee',
                        '- TZS ${Validators.formatNumber(_fee)}',
                        SColors.red,
                      ),
                      const Divider(color: SColors.navyLight, height: 16),
                      _row(
                        'Total deducted',
                        'TZS ${Validators.formatNumber(_amount + _fee)}',
                        SColors.textPrimary,
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
                  onPressed: _submit,
                  style: SButton.primary,
                  child: const Text(
                    'Transfer Now',
                    style: SButton.primaryLabel,
                  ),
                ),
              ),

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
                    const Icon(
                      Icons.schedule_outlined,
                      color: SColors.gold,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bank transfers take 1-3 business days. TZS 2,000 flat fee applies.',
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
    if (_accountCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter account number.');
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter account name.');
      return;
    }
    if (_amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (_amount + _fee > widget.balanceTzs) {
      setState(() => _error = 'Insufficient balance.');
      return;
    }

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
          'Bank transfers will be available in the next release.',
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
