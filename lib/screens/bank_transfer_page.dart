import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';

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
  double get _fee => 2000;

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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textSub, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l.bankTransfer,
          style: TextStyle(
            color: textPrimary,
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
              // ── Balance card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
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
                        Icons.account_balance_outlined,
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
                          'TZS ${Validators.formatNumber(widget.balanceTzs)}',
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

              // ── Bank selector ────────────────────────────────────────
              Text(
                l.selectBank,
                style: TextStyle(
                  color: textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                        color: sel ? SColors.gold.withOpacity(0.15) : cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? SColors.gold : borderColor,
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
                              color: sel ? SColors.gold : textSub,
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

              // ── Account number ───────────────────────────────────────
              Text(
                l.accountNumber,
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
                  controller: _accountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l.isSwahili
                        ? 'Weka nambari ya akaunti'
                        : 'Enter account number',
                    hintStyle: TextStyle(color: textDim, fontSize: 15),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.credit_card_outlined,
                        color: textDim,
                        size: 18,
                      ),
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
              const SizedBox(height: 16),

              // ── Account name ─────────────────────────────────────────
              Text(
                l.accountName,
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
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: l.isSwahili
                        ? 'Jina la mmiliki wa akaunti'
                        : 'Account holder name',
                    hintStyle: TextStyle(color: textDim, fontSize: 15),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.person_outline,
                        color: textDim,
                        size: 18,
                      ),
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
              const SizedBox(height: 16),

              // ── Amount ───────────────────────────────────────────────
              Text(
                '${l.amount} (TZS)',
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
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
                    prefixText: 'TZS  ',
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

              if (_amount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _row(
                        l.isSwahili ? 'Kiasi cha uhamisho' : 'Transfer amount',
                        'TZS ${Validators.formatNumber(_amount)}',
                        textPrimary,
                        textSub,
                      ),
                      const SizedBox(height: 6),
                      _row(
                        l.isSwahili ? 'Ada ya benki' : 'Bank fee',
                        '- TZS ${Validators.formatNumber(_fee)}',
                        SColors.red,
                        textSub,
                      ),
                      Divider(color: borderColor, height: 16),
                      _row(
                        l.totalDeducted,
                        'TZS ${Validators.formatNumber(_amount + _fee)}',
                        textPrimary,
                        textSub,
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
                  onPressed: () =>
                      _submit(context, l, cardColor, textPrimary, textSub),
                  style: SButton.primary,
                  child: Text(l.transferNow, style: SButton.primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    String l,
    String v,
    Color vc,
    Color labelColor, {
    bool bold = false,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: TextStyle(color: labelColor, fontSize: 13)),
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

  void _submit(
    BuildContext context,
    AppLocalizations l,
    Color cardColor,
    Color textPrimary,
    Color textSub,
  ) {
    setState(() => _error = '');
    if (_accountCtrl.text.trim().isEmpty) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka nambari ya akaunti.'
            : 'Enter account number.',
      );
      return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka jina la akaunti.'
            : 'Enter account name.',
      );
      return;
    }
    if (_amount <= 0) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka kiasi sahihi.'
            : 'Enter a valid amount.',
      );
      return;
    }
    if (_amount + _fee > widget.balanceTzs) {
      setState(() => _error = l.insufficientBal);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.comingSoon,
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          l.isSwahili
              ? 'Uhamisho wa benki utapatikana katika toleo lijalo.'
              : 'Bank transfers will be available in the next release.',
          style: TextStyle(color: textSub, fontSize: 13),
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
