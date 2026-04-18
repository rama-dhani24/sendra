import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/services/transaction_service.dart';
import 'package:sendra/screens/receipt_screen.dart';

class TransfersPage extends StatefulWidget {
  final String userId;

  const TransfersPage({super.key, required this.userId});

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage>
    with SingleTickerProviderStateMixin {
  // Filter: 0 = All, 1 = Sent, 2 = Received
  int _filterIndex = 0;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilterTabs(),
            const SizedBox(height: 16),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ── Page title + summary ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfers',
            style: TextStyle(
              color: SColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          StreamBuilder<QuerySnapshot>(
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
              final count = snap.data?.docs.length ?? 0;
              return Text(
                '$count transaction${count == 1 ? '' : 's'} total',
                style: SText.caption,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Filter tabs ────────────────────────────────────────────────────────────
  Widget _buildFilterTabs() {
    final labels = ['All', 'Sent', 'Received'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SColors.navyLight, width: 1),
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final active = i == _filterIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filterIndex = i),
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

  // ── Transaction list ───────────────────────────────────────────────────────
  Widget _buildList() {
    // Build stream based on filter
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      FSKeys.transactionsCollection,
    );

    if (_filterIndex == 1) {
      // Sent only
      query = query.where(TxKeys.senderId, isEqualTo: widget.userId);
    } else if (_filterIndex == 2) {
      // Received only
      query = query.where(TxKeys.receiverId, isEqualTo: widget.userId);
    } else {
      // All — compound OR filter
      query = query.where(
        Filter.or(
          Filter(TxKeys.senderId, isEqualTo: widget.userId),
          Filter(TxKeys.receiverId, isEqualTo: widget.userId),
        ),
      );
    }

    query = query.orderBy(TxKeys.createdAt, descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
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
                'Could not load transactions.\n${snap.error}',
                style: SText.caption,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        // Group by date
        final grouped = <String, List<QueryDocumentSnapshot>>{};
        for (final doc in docs) {
          final data = doc.data()! as Map<String, dynamic>;
          final ts = data[TxKeys.createdAt] as Timestamp?;
          final dt = ts?.toDate() ?? DateTime.now();
          final key = _groupKey(dt);
          grouped.putIfAbsent(key, () => []).add(doc);
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
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
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

  Widget _buildEmptyState() {
    final messages = [
      'No transactions yet.',
      'No sent transactions.',
      'No received transactions.',
    ];
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SColors.navyCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: SColors.textDim,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(messages[_filterIndex], style: SText.caption),
          const SizedBox(height: 6),
          Text('Transactions will appear here.', style: SText.tiny),
        ],
      ),
    );
  }

  // ── Date group key ─────────────────────────────────────────────────────────
  String _groupKey(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);

    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';

    final months = [
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Transaction card ──────────────────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String userId;

  const _TxCard({required this.doc, required this.userId});

  @override
  Widget build(BuildContext context) {
    final data = doc.data()! as Map<String, dynamic>;
    final isSender = data[TxKeys.senderId] == userId;

    final sentCurrency = data[TxKeys.sentCurrency] as String? ?? 'TZS';
    final sentAmt = (data[TxKeys.sentAmount] as num?)?.toDouble() ?? 0;
    final amountTzs = (data[TxKeys.amountTzs] as num?)?.toDouble() ?? 0;
    final feeTzs = (data[TxKeys.feeTzs] as num?)?.toDouble() ?? 0;
    final totalDebited =
        (data[TxKeys.totalDebitedTzs] as num?)?.toDouble() ?? 0;
    final receivedTzs = (data[TxKeys.receivedTzs] as num?)?.toDouble() ?? 0;

    final counterparty = isSender
        ? data[TxKeys.receiverName] as String? ?? ''
        : data[TxKeys.senderName] as String? ?? '';
    final counterAcc = isSender
        ? data[TxKeys.receiverAccNumber] as String? ?? ''
        : data[TxKeys.senderAccNumber] as String? ?? '';

    final ts = data[TxKeys.createdAt] as Timestamp?;
    final dt = ts?.toDate() ?? DateTime.now();
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final flag = AppRates.currencyFlags[sentCurrency] ?? '💰';
    final txId = '#${doc.id.substring(0, 8).toUpperCase()}';
    final status = data[TxKeys.status] as String? ?? 'completed';

    return GestureDetector(
      onTap: () {
        // Tap to view receipt
        final tx = TransactionModel(
          id: doc.id,
          senderId: data[TxKeys.senderId] as String? ?? '',
          senderName: data[TxKeys.senderName] as String? ?? '',
          senderAccNumber: data[TxKeys.senderAccNumber] as String? ?? '',
          receiverId: data[TxKeys.receiverId] as String? ?? '',
          receiverName: data[TxKeys.receiverName] as String? ?? '',
          receiverAccNumber: data[TxKeys.receiverAccNumber] as String? ?? '',
          sentCurrency: data[TxKeys.sentCurrency] as String? ?? 'TZS',
          sentAmount: (data[TxKeys.sentAmount] as num?)?.toDouble() ?? 0,
          usdtAmount: (data[TxKeys.usdtAmount] as num?)?.toDouble() ?? 0,
          amountTzs: amountTzs,
          feeTzs: feeTzs,
          totalDebitedTzs: totalDebited,
          receivedTzs: receivedTzs,
          createdAt: dt,
          status: status,
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ReceiptScreen(transaction: tx)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SColors.navyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SColors.navyLight, width: 1),
        ),
        child: Column(
          children: [
            // ── Top row ───────────────────────────────────────────────────
            Row(
              children: [
                // Flag + direction icon stack
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

                // Name + ID
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

                // Amount column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Primary amount
                    Text(
                      isSender
                          ? '−${sentAmt.toStringAsFixed(2)} $sentCurrency'
                          : '+TZS ${Validators.formatNumber(receivedTzs)}',
                      style: TextStyle(
                        color: isSender ? SColors.red : SColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Secondary line
                    const SizedBox(height: 2),
                    Text(
                      isSender
                          ? '−TZS ${Validators.formatNumber(totalDebited)} total'
                          : '+TZS ${Validators.formatNumber(amountTzs)} gross',
                      style: const TextStyle(
                        color: SColors.textDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Bottom detail row ─────────────────────────────────────────
            const SizedBox(height: 12),
            Container(height: 1, color: SColors.navyLight),
            const SizedBox(height: 10),
            Row(
              children: [
                // Tx ID
                Text(txId, style: SText.tiny),
                const Spacer(),
                // Fee chip (sender only)
                if (isSender) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: SColors.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Fee: TZS ${Validators.formatNumber(feeTzs)}',
                      style: const TextStyle(
                        color: SColors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SColors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: const TextStyle(
                      color: SColors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Tap hint
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
}
