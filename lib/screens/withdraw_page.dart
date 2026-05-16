import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';

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
  final bool _loading = false;
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
          l.withdrawTitle,
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

              // ── Method selector ──────────────────────────────────────
              Text(
                l.withdrawalMethod,
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
                        color: sel ? SColors.gold.withOpacity(0.15) : cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? SColors.gold : borderColor,
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
                              color: sel ? SColors.gold : textSub,
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

              // ── Phone number ─────────────────────────────────────────
              Text(
                l.mobileNumber,
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
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: TextStyle(color: textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '07XXXXXXXX',
                    hintStyle: TextStyle(color: textDim, fontSize: 15),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.phone_outlined,
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
              const SizedBox(height: 20),

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

              // ── Fee breakdown ────────────────────────────────────────
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
                        l.isSwahili ? 'Kiasi cha kutoa' : 'Withdrawal amount',
                        'TZS ${Validators.formatNumber(_amount)}',
                        textPrimary,
                        textSub,
                      ),
                      const SizedBox(height: 6),
                      _row(
                        l.isSwahili ? 'Ada (1%)' : 'Fee (1%)',
                        '- TZS ${Validators.formatNumber(_fee)}',
                        SColors.red,
                        textSub,
                      ),
                      Divider(color: borderColor, height: 16),
                      _row(
                        l.isSwahili ? 'Utapokea' : 'You receive',
                        'TZS ${Validators.formatNumber(_amount - _fee)}',
                        SColors.green,
                        textSub,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],

              // ── Error box ────────────────────────────────────────────
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
                  onPressed: _loading
                      ? null
                      : () => _submit(
                          context,
                          l,
                          cardColor,
                          textPrimary,
                          textSub,
                        ),
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
                      : Text(l.withdrawNow, style: SButton.primaryLabel),
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
                        l.isSwahili
                            ? 'Kutoa pesa huchukua dakika 1-5. Inapatikana masaa 24/7.'
                            : 'Withdrawals are processed within 1-5 minutes. Available 24/7.',
                        style: TextStyle(color: textSub, fontSize: 11),
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

  Widget _row(
    String label,
    String value,
    Color valueColor,
    Color labelColor, {
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

  void _submit(
    BuildContext context,
    AppLocalizations l,
    Color cardColor,
    Color textPrimary,
    Color textSub,
  ) {
    setState(() => _error = '');
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || !Validators.isValidTZPhone(phone)) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka nambari sahihi ya simu ya Tanzania.'
            : 'Enter a valid Tanzanian phone number.',
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
    if (_total > widget.balanceTzs) {
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
              ? 'Kutoa pesa kupitia simu kutapatikana katika toleo lijalo.'
              : 'Mobile money withdrawals will be available in the next release.',
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
