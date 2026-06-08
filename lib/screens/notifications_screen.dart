import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  // ── Firestore stream — NO orderBy to avoid index/missing-field drops ───────
  // We sort client-side after receiving all docs safely.
  Stream<QuerySnapshot> get _stream => FirebaseFirestore.instance
      .collection(FSKeys.notificationsCollection)
      .where(NotifKeys.userId, isEqualTo: userId)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final unreadBg = isDark ? SColors.navy : const Color(0xFFF0F4FF);
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
          l.notifications,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Mark all as read
          TextButton(
            onPressed: () => _markAllRead(),
            child: Text(
              l.markAllRead,
              style: const TextStyle(
                color: SColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (ctx, snap) {
          // ── Loading ─────────────────────────────────────────────────────
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: SColors.gold,
                strokeWidth: 2,
              ),
            );
          }

          // ── Error ────────────────────────────────────────────────────────
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.isSwahili
                      ? 'Hitilafu kupakia arifa.'
                      : 'Error loading notifications.',
                  style: TextStyle(color: textSub, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ── Sort client-side by createdAt desc (safe — no missing-field drop) ─
          final rawDocs = List<QueryDocumentSnapshot>.from(
            snap.data?.docs ?? [],
          );

          rawDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = aData[NotifKeys.createdAt] as Timestamp?;
            final bTs = bData[NotifKeys.createdAt] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs); // descending
          });

          // ── Empty state ──────────────────────────────────────────────────
          if (rawDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      color: textDim,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.noNotifications,
                    style: TextStyle(color: textSub, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // ── List ─────────────────────────────────────────────────────────
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            itemCount: rawDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final data = rawDocs[i].data()! as Map<String, dynamic>;
              final docId = rawDocs[i].id;
              final type = data[NotifKeys.type] as String? ?? 'credit';
              final isCredit = type == 'credit';
              final isRead = data[NotifKeys.isRead] as bool? ?? false;
              final amount = (data[NotifKeys.amount] as num?)?.toDouble() ?? 0;
              final title = data[NotifKeys.title] as String? ?? '';
              final body = data[NotifKeys.body] as String? ?? '';
              final ts = data[NotifKeys.createdAt] as Timestamp?;
              final dt = ts?.toDate();

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    FirebaseFirestore.instance
                        .collection(FSKeys.notificationsCollection)
                        .doc(docId)
                        .update({NotifKeys.isRead: true});
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? cardColor : unreadBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? borderColor
                          : isCredit
                          ? SColors.green.withOpacity(0.35)
                          : SColors.red.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ── Icon ─────────────────────────────────────────
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCredit
                              ? SColors.green.withOpacity(0.12)
                              : SColors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isCredit
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isCredit ? SColors.green : SColors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Content ───────────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!isRead) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: SColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              body,
                              style: TextStyle(color: textSub, fontSize: 13),
                            ),
                            if (dt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _fmtDate(dt, l),
                                style: TextStyle(color: textDim, fontSize: 10),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ── Amount ────────────────────────────────────────
                      Text(
                        '${isCredit ? '+' : '-'}TZS\n${_fmt(amount)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isCredit ? SColors.green : SColors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Mark all as read ───────────────────────────────────────────────────────
  Future<void> _markAllRead() async {
    final snap = await FirebaseFirestore.instance
        .collection(FSKeys.notificationsCollection)
        .where(NotifKeys.userId, isEqualTo: userId)
        .where(NotifKeys.isRead, isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {NotifKeys.isRead: true});
    }
    await batch.commit();
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _fmtDate(DateTime dt, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (d == today) return '${l.today}, $h:$m';
    if (d == today.subtract(const Duration(days: 1)))
      return '${l.yesterday}, $h:$m';
    return '${dt.day}/${dt.month}/${dt.year}, $h:$m';
  }
}
