import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

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
          'Pay Bills',
          style: TextStyle(
            color: SColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _selectedBill == null ? _buildSelector() : _buildForm(),
      ),
    );
  }

  Widget _buildSelector() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select a bill to pay', style: SText.caption),
        const SizedBox(height: 16),
        ...(_bills.map(
          (b) => GestureDetector(
            onTap: () => setState(() => _selectedBill = b['name'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SColors.navyCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SColors.navyLight),
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
                      style: const TextStyle(
                        color: SColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SColors.textDim,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildForm() {
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
                  'Back to bills',
                  style: const TextStyle(color: SColors.gold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedBill!,
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Available: TZS ${Validators.formatNumber(widget.balanceTzs)}',
            style: SText.caption,
          ),
          const SizedBox(height: 24),
          Text('Account / Meter Number', style: SText.label),
          const SizedBox(height: 8),
          Container(
            decoration: SDecor.inputField,
            child: TextField(
              controller: accountCtrl,
              keyboardType: TextInputType.number,
              style: SText.body,
              decoration: SDecor.textInput(
                hint: 'Enter number',
                prefix: const Icon(
                  Icons.numbers_rounded,
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
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => showDialog(
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
                    'Bill payments coming in next release.',
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
              ),
              style: SButton.primary,
              child: const Text('Pay Now', style: SButton.primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
