import 'package:flutter/material.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';

class BillsPage extends StatefulWidget {
  final String userId;
  final double balanceTzs;
  const BillsPage({super.key, required this.userId, required this.balanceTzs});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  String? _selectedBill;

  static const _bills = [
    {'name': 'LUKU (Electricity)', 'icon': '⚡', 'color': 0xFFF59E0B},
    {'name': 'DAWASCO (Water)', 'icon': '💧', 'color': 0xFF3B82F6},
    {'name': 'TTCL (Landline)', 'icon': '📞', 'color': 0xFF10B981},
    {'name': 'DSTV / StarTimes', 'icon': '📺', 'color': 0xFF8B5CF6},
    {'name': 'Internet', 'icon': '🌐', 'color': 0xFF06B6D4},
    {'name': 'School Fees', 'icon': '🎓', 'color': 0xFFEC4899},
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

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
          l.payBills,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _selectedBill == null
            ? _buildSelector(context, l, isDark)
            : _buildForm(context, l, isDark),
      ),
    );
  }

  Widget _buildSelector(BuildContext context, AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.isSwahili ? 'Chagua bili ya kulipa' : 'Select a bill to pay',
          style: TextStyle(color: textSub, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ..._bills.map(
          (b) => GestureDetector(
            onTap: () => setState(() => _selectedBill = b['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(b['color'] as int).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        b['icon'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      b['name'] as String,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? SColors.textDim : SColors.lightTextDim,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    final amountCtrl = TextEditingController();
    final accountCtrl = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedBill = null),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  color: SColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  l.isSwahili ? 'Rudi kwa bili' : 'Back to bills',
                  style: const TextStyle(color: SColors.gold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedBill!,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l.availableBalance}: TZS ${Validators.formatNumber(widget.balanceTzs)}',
            style: TextStyle(color: textSub, fontSize: 13),
          ),
          const SizedBox(height: 24),

          Text(
            l.isSwahili
                ? 'Nambari ya Akaunti / Mita'
                : 'Account / Meter Number',
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
              controller: accountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: textPrimary, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: l.isSwahili ? 'Weka nambari' : 'Enter number',
                hintStyle: TextStyle(color: textDim, fontSize: 15),
                prefixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.numbers_rounded, color: textDim, size: 18),
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
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    l.comingSoon,
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    l.isSwahili
                        ? 'Malipo ya bili yanakuja.'
                        : 'Bill payments coming in next release.',
                    style: TextStyle(color: textSub, fontSize: 13),
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
              ),
              style: SButton.primary,
              child: Text(l.payNow, style: SButton.primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
