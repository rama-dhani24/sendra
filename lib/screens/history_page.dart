import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/screens/receipt_screen.dart';
import 'package:sendra/screens/transaction_service.dart';

class HistoryPage extends StatefulWidget {
  final String userId;
  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  int _filter = 0; // 0=All, 1=Sent, 2=Received

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
    _animCtrl.dispose();
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
          'Transaction History',
          style: TextStyle(
            color: SColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildSummaryBar(),
            const SizedBox(height: 12),
            _buildFilterTabs(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FSKeys.transactionsCollection)
          .where(
            Filter.or(
              Filter(TxKeys.senderId, isEqualTo: widget.userId),
              Filter(TxKeys.receiverId, isEqualTo: widget.userId),
            ),
          )
          .snapshots(),
      builder: (ctx, snap) {
        double totalSent = 0, totalReceived = 0;
        int sentCount = 0, receivedCount = 0;

        for (final doc in snap.data?.docs ?? []) {
          final data = doc.data()! as Map<String, dynamic>;
          final isSender = data[TxKeys.senderId] == widget.userId;
          if (isSender) {
            totalSent +=
                (data[TxKeys.totalDebitedTzs] as num?)?.toDouble() ?? 0;
            sentCount++;
          } else {
            totalReceived +=
                (data[TxKeys.receivedTzs] as num?)?.toDouble() ?? 0;
            receivedCount++;
          }
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Total Sent',
                  value: 'TZS ${Validators.formatNumber(totalSent)}',
                  sub: '$sentCount transactions',
                  color: SColors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Total Received',
                  value: 'TZS ${Validators.formatNumber(totalReceived)}',
                  sub: '$receivedCount transactions',
                  color: SColors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Filter tabs ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    const labels = ['All', 'Sent', 'Received'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SColors.navyLight),
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = i == _filter;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? SColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        color: active ? SColors.navy : SColors.textSub,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Transaction list ──────────────────────────────────────────────────────
  Widget _buildList() {
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance.collection(
      FSKeys.transactionsCollection,
    );

    if (_filter == 1) {
      q = q.where(TxKeys.senderId, isEqualTo: widget.userId);
    } else if (_filter == 2) {
      q = q.where(TxKeys.receiverId, isEqualTo: widget.userId);
    } else {
      q = q.where(
        Filter.or(
          Filter(TxKeys.senderId, isEqualTo: widget.userId),
          Filter(TxKeys.receiverId, isEqualTo: widget.userId),
        ),
      );
    }
    q = q.orderBy(TxKeys.createdAt, descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: SColors.gold,
              strokeWidth: 2,
            ),
          );
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading transactions.\n${snap.error}',
                style: SText.caption,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmpty();

        // Group by date
        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (final doc in docs) {
          final data = doc.data()! as Map<String, dynamic>;
          final ts = data[TxKeys.createdAt] as Timestamp?;
          final dt = ts?.toDate() ?? DateTime.now();
          grouped.putIfAbsent(_groupKey(dt), () => []).add(doc);
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          itemCount: grouped.length,
          itemBuilder: (ctx, gi) {
            final dateKey = grouped.keys.elementAt(gi);
            final txDocs = grouped[dateKey]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    dateKey,
                    style: const TextStyle(
                      color: SColors.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                ...txDocs.map(
                  (doc) => _TxCard(doc: doc, userId: widget.userId),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmpty() {
    const msgs = [
      'No transactions yet.',
      'No sent transactions.',
      'No received transactions.',
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: SColors.navyCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: SColors.textDim,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(msgs[_filter], style: SText.caption),
          const SizedBox(height: 4),
          Text('Your transactions will appear here.', style: SText.tiny),
        ],
      ),
    );
  }

  String _groupKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}

// ─── Transaction card ─────────────────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String userId;
  const _TxCard({required this.doc, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Build TransactionModel from the Firestore doc
    final tx = TransactionModel.fromDoc(doc);
    final isSender = tx.senderId == userId;
    final flag = AppRates.currencyFlags[tx.sentCurrency] ?? '💰';
    final txId = '#${doc.id.substring(0, 8).toUpperCase()}';
    final time =
        '${tx.createdAt.hour.toString().padLeft(2, '0')}:'
        '${tx.createdAt.minute.toString().padLeft(2, '0')}';

    final counterparty = isSender ? tx.receiverName : tx.senderName;
    final counterAcc = isSender ? tx.receiverAccNumber : tx.senderAccNumber;

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ReceiptScreen(transaction: tx))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SColors.navyLight),
        ),
        child: Column(
          children: [
            // Main row
            Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSender
                              ? SColors.red.withOpacity(0.10)
                              : SColors.green.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            flag,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isSender ? SColors.red : SColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSender
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterparty,
                        style: const TextStyle(
                          color: SColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text('ID $counterAcc · $time', style: SText.tiny),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSender
                          ? '−${tx.sentAmount.toStringAsFixed(2)} ${tx.sentCurrency}'
                          : '+TZS ${Validators.formatNumber(tx.receivedTzs)}',
                      style: TextStyle(
                        color: isSender ? SColors.red : SColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSender
                          ? '−TZS ${Validators.formatNumber(tx.totalDebitedTzs)} total'
                          : '+TZS ${Validators.formatNumber(tx.amountTzs)} gross',
                      style: const TextStyle(
                        color: SColors.textDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Detail row
            const SizedBox(height: 10),
            Container(height: 1, color: SColors.navyBorder),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(txId, style: SText.tiny),
                const Spacer(),
                if (isSender && tx.feeTzs > 0) ...[
                  _badge(
                    'Fee TZS ${Validators.formatNumber(tx.feeTzs)}',
                    SColors.red,
                  ),
                  const SizedBox(width: 6),
                ],
                _badge(
                  tx.status[0].toUpperCase() + tx.status.substring(1),
                  SColors.green,
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SColors.textDim,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}

// ─── Stat card ────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SColors.navyLight),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: SColors.textDim, fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(sub, style: SText.tiny),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
