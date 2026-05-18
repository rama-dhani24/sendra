import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';
import 'package:sendra/screens/transaction_service.dart';
import 'package:sendra/screens/receipt_screen.dart';

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

  // ── Sorted helper — used by both summary and list ─────────────────────────
  /// Returns a stream with NO orderBy/Filter.or to avoid index requirements.
  /// We filter & sort entirely on the client side.
  Stream<QuerySnapshot> _streamAll() => FirebaseFirestore.instance
      .collection(FSKeys.transactionsCollection)
      .where(TxKeys.senderId, isEqualTo: widget.userId)
      .snapshots();

  Stream<QuerySnapshot> _streamReceived() => FirebaseFirestore.instance
      .collection(FSKeys.transactionsCollection)
      .where(TxKeys.receiverId, isEqualTo: widget.userId)
      .snapshots();

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
          l.transactionHistory,
          style: TextStyle(
            color: textPrimary,
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
            _buildSummaryBar(context, l, isDark),
            const SizedBox(height: 12),
            _buildFilterTabs(context, l, isDark),
            const SizedBox(height: 8),
            Expanded(child: _buildList(context, l, isDark)),
          ],
        ),
      ),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────────────────
  // Uses two simple single-field queries — no composite index needed.
  Widget _buildSummaryBar(
    BuildContext context,
    AppLocalizations l,
    bool isDark,
  ) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combinedStream(),
      builder: (ctx, snap) {
        double totalSent = 0, totalReceived = 0;
        int sentCount = 0, receivedCount = 0;

        if (snap.hasData) {
          // snap.data![0] = sent docs, snap.data![1] = received docs
          for (final doc in snap.data![0].docs) {
            final data = doc.data()! as Map<String, dynamic>;
            totalSent +=
                (data[TxKeys.totalDebitedTzs] as num?)?.toDouble() ?? 0;
            sentCount++;
          }
          for (final doc in snap.data![1].docs) {
            final data = doc.data()! as Map<String, dynamic>;
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
                  label: l.totalSent,
                  value: 'TZS ${Validators.formatNumber(totalSent)}',
                  sub: l.isSwahili
                      ? '$sentCount miamala'
                      : '$sentCount transactions',
                  color: SColors.red,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.arrow_downward_rounded,
                  label: l.totalReceived,
                  value: 'TZS ${Validators.formatNumber(totalReceived)}',
                  sub: l.isSwahili
                      ? '$receivedCount miamala'
                      : '$receivedCount transactions',
                  color: SColors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Combines two streams into one to power the summary bar.
  Stream<List<QuerySnapshot>> _combinedStream() {
    return _streamAll().asyncMap((sent) async {
      final received = await FirebaseFirestore.instance
          .collection(FSKeys.transactionsCollection)
          .where(TxKeys.receiverId, isEqualTo: widget.userId)
          .get();
      return [sent, received];
    });
  }

  // ── Filter tabs ───────────────────────────────────────────────────────────
  Widget _buildFilterTabs(
    BuildContext context,
    AppLocalizations l,
    bool isDark,
  ) {
    final labels = [l.all, l.sent, l.received];
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
                        color: active ? SColors.navy : textSub,
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
  // KEY FIX: Each filter uses a SIMPLE single-field where() with NO orderBy.
  // Sorting and merging happen entirely client-side.
  Widget _buildList(BuildContext context, AppLocalizations l, bool isDark) {
    if (_filter == 1) {
      // Sent only — single where, no composite index needed
      return StreamBuilder<QuerySnapshot>(
        stream: _streamAll(),
        builder: (ctx, snap) =>
            _buildListContent(ctx, snap, l, isDark, onlySent: true),
      );
    } else if (_filter == 2) {
      // Received only — single where, no composite index needed
      return StreamBuilder<QuerySnapshot>(
        stream: _streamReceived(),
        builder: (ctx, snap) =>
            _buildListContent(ctx, snap, l, isDark, onlyReceived: true),
      );
    } else {
      // All — merge two streams client-side
      return StreamBuilder<List<QuerySnapshot>>(
        stream: _combinedStream(),
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
            return _errorWidget(snap.error.toString(), l, isDark);
          }

          // Merge both result sets
          final allDocs = <QueryDocumentSnapshot>[
            ...snap.data![0].docs,
            ...snap.data![1].docs,
          ];

          return _renderDocs(allDocs, l, isDark);
        },
      );
    }
  }

  Widget _buildListContent(
    BuildContext ctx,
    AsyncSnapshot<QuerySnapshot> snap,
    AppLocalizations l,
    bool isDark, {
    bool onlySent = false,
    bool onlyReceived = false,
  }) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: SColors.gold, strokeWidth: 2),
      );
    }
    if (snap.hasError) {
      return _errorWidget(snap.error.toString(), l, isDark);
    }

    return _renderDocs(snap.data?.docs ?? [], l, isDark);
  }

  Widget _renderDocs(
    List<QueryDocumentSnapshot> rawDocs,
    AppLocalizations l,
    bool isDark,
  ) {
    if (rawDocs.isEmpty) return _buildEmpty(l, isDark);

    // Remove duplicates (a doc can appear in both sent & received streams
    // if somehow a user is both sender and receiver — unlikely but safe)
    final seen = <String>{};
    final unique = rawDocs.where((d) => seen.add(d.id)).toList();

    // Sort descending by createdAt (nulls go last)
    unique.sort((a, b) {
      final aTs =
          (a.data() as Map<String, dynamic>)[TxKeys.createdAt] as Timestamp?;
      final bTs =
          (b.data() as Map<String, dynamic>)[TxKeys.createdAt] as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return bTs.compareTo(aTs);
    });

    // Group by date
    final grouped = <String, List<QueryDocumentSnapshot>>{};
    for (final doc in unique) {
      final data = doc.data()! as Map<String, dynamic>;
      final ts = data[TxKeys.createdAt] as Timestamp?;
      final dt = ts?.toDate() ?? DateTime.now();
      grouped.putIfAbsent(_groupKey(dt, l), () => []).add(doc);
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
                style: TextStyle(
                  color: isDark ? SColors.textSub : SColors.lightTextSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            ...txDocs.map(
              (doc) => _TxCard(
                doc: doc,
                userId: widget.userId,
                isDark: isDark,
                l: l,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _errorWidget(String error, AppLocalizations l, bool isDark) {
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          l.isSwahili
              ? 'Hitilafu kupakia miamala.'
              : 'Error loading transactions.',
          style: TextStyle(color: textSub, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l, bool isDark) {
    final msgs = [
      l.noTransactions,
      l.isSwahili ? 'Hakuna miamala iliyotumwa.' : 'No sent transactions.',
      l.isSwahili
          ? 'Hakuna miamala iliyopokelewa.'
          : 'No received transactions.',
    ];
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isDark ? SColors.navyCard : SColors.lightCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.receipt_long_rounded, color: textDim, size: 28),
          ),
          const SizedBox(height: 14),
          Text(msgs[_filter], style: TextStyle(color: textSub, fontSize: 13)),
          const SizedBox(height: 4),
          Text(l.txWillAppear, style: TextStyle(color: textDim, fontSize: 11)),
        ],
      ),
    );
  }

  String _groupKey(DateTime dt, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return l.today;
    if (d == today.subtract(const Duration(days: 1))) {
      return l.yesterday;
    }
    const months = [
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
  final bool isDark;
  final AppLocalizations l;

  const _TxCard({
    required this.doc,
    required this.userId,
    required this.isDark,
    required this.l,
  });

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
    final usdtToTzsRate =
        (data['usdtToTzsRate'] as num?)?.toDouble() ?? AppRates.usdtToTzs;

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

    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final dividerColor = isDark ? SColors.navyBorder : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return GestureDetector(
      onTap: () {
        final tx = TransactionModel(
          id: doc.id,
          senderId: data[TxKeys.senderId] as String? ?? '',
          senderName: data[TxKeys.senderName] as String? ?? '',
          senderAccNumber: data[TxKeys.senderAccNumber] as String? ?? '',
          receiverId: data[TxKeys.receiverId] as String? ?? '',
          receiverName: data[TxKeys.receiverName] as String? ?? '',
          receiverAccNumber: data[TxKeys.receiverAccNumber] as String? ?? '',
          sentCurrency: sentCurrency,
          sentAmount: sentAmt,
          usdtAmount: (data[TxKeys.usdtAmount] as num?)?.toDouble() ?? 0,
          amountTzs: amountTzs,
          feeTzs: feeTzs,
          totalDebitedTzs: totalDebited,
          receivedTzs: receivedTzs,
          usdtToTzsRate: usdtToTzsRate,
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
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          children: [
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
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID $counterAcc · $time',
                        style: TextStyle(color: textDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
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
                    const SizedBox(height: 2),
                    Text(
                      isSender
                          ? '−TZS ${Validators.formatNumber(totalDebited)} ${l.isSwahili ? 'jumla' : 'total'}'
                          : '+TZS ${Validators.formatNumber(amountTzs)} ${l.isSwahili ? 'kabla' : 'gross'}',
                      style: TextStyle(color: textDim, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: dividerColor),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(txId, style: TextStyle(color: textDim, fontSize: 11)),
                const Spacer(),
                if (isSender && feeTzs > 0) ...[
                  _badge(
                    '${l.isSwahili ? 'Ada' : 'Fee'} TZS ${Validators.formatNumber(feeTzs)}',
                    SColors.red,
                  ),
                  const SizedBox(width: 6),
                ],
                _badge(
                  status[0].toUpperCase() + status.substring(1),
                  SColors.green,
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: textDim, size: 14),
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
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
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
                Text(label, style: TextStyle(color: textDim, fontSize: 10)),
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
                Text(sub, style: TextStyle(color: textDim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
