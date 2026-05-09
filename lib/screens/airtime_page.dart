import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

class AirtimePage extends StatefulWidget {
  final String userId;
  final double balanceTzs;
  const AirtimePage({
    super.key,
    required this.userId,
    required this.balanceTzs,
  });

  @override
  State<AirtimePage> createState() => _AirtimePageState();
}

class _AirtimePageState extends State<AirtimePage> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _network = 'Vodacom';
  String _error = '';
  double _selected = 0;

  static const _networks = ['Vodacom', 'Tigo', 'Airtel', 'Halotel', 'TTCL'];
  static const _networkColors = {
    'Vodacom': 0xFFEF4444,
    'Tigo': 0xFF3B82F6,
    'Airtel': 0xFFEF4444,
    'Halotel': 0xFFF59E0B,
    'TTCL': 0xFF10B981,
  };
  static const _quickAmounts = [1000.0, 2000.0, 5000.0, 10000.0, 20000.0];

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

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
          'Buy Airtime',
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
                        Icons.phone_android_outlined,
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

              Text('Network', style: SText.label),
              const SizedBox(height: 10),
              Row(
                children: _networks.map((n) {
                  final sel = n == _network;
                  final color = Color(_networkColors[n] ?? 0xFF6B7280);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _network = n),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? color.withOpacity(0.15)
                              : SColors.navyCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? color : SColors.navyLight,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  n[0],
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n,
                              style: TextStyle(
                                color: sel ? color : SColors.textDim,
                                fontSize: 9,
                                fontWeight: sel
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
              const SizedBox(height: 20),

              Text('Phone Number', style: SText.label),
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

              Text('Amount (TZS)', style: SText.label),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAmounts.map((a) {
                  final sel = a == _selected;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = a;
                        _amountCtrl.text = a.toInt().toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
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
                      child: Text(
                        'TZS ${Validators.formatNumber(a)}',
                        style: TextStyle(
                          color: sel ? SColors.gold : SColors.textSub,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: SDecor.inputField,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() => _selected = 0),
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: SDecor.textInput(
                    hint: 'Custom amount',
                    prefixText: 'TZS  ',
                    prefixStyle: const TextStyle(
                      color: SColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

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
                  onPressed: () {
                    setState(() => _error = '');
                    final phone = _phoneCtrl.text.trim();
                    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
                    if (!Validators.isValidTZPhone(phone)) {
                      setState(() => _error = 'Enter a valid phone number.');
                      return;
                    }
                    if (amt <= 0) {
                      setState(() => _error = 'Enter a valid amount.');
                      return;
                    }
                    if (amt > widget.balanceTzs) {
                      setState(() => _error = 'Insufficient balance.');
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: SColors.navyCard,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: SColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Airtime purchase coming in next release.',
                          style: SText.caption,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'OK',
                              style: TextStyle(color: SColors.gold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: SButton.primary,
                  child: const Text('Buy Airtime', style: SButton.primaryLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
