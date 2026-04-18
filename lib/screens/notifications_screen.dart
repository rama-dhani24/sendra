import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

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
        title: Text('Notifications', style: SText.sectionTitle),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FSKeys.notificationsCollection)
            .where(NotifKeys.userId, isEqualTo: userId)
            .orderBy(NotifKeys.createdAt, descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: SColors.gold,
                strokeWidth: 2,
              ),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
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
                      Icons.notifications_off_outlined,
                      color: SColors.textDim,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: SText.caption),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final docId = docs[i].id;
              final type = data[NotifKeys.type] as String? ?? 'credit';
              final isCredit = type == 'credit';
              final isRead = data[NotifKeys.isRead] as bool? ?? false;
              final amount = (data[NotifKeys.amount] as num?)?.toDouble() ?? 0;

              return GestureDetector(
                onTap: () {
                  // Mark as read
                  if (!isRead) {
                    FirebaseFirestore.instance
                        .collection(FSKeys.notificationsCollection)
                        .doc(docId)
                        .update({NotifKeys.isRead: true});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRead ? SColors.navyCard : SColors.navy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? SColors.navyLight
                          : isCredit
                          ? SColors.green.withOpacity(0.35)
                          : SColors.red.withOpacity(0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Icon
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

                      // Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  data[NotifKeys.title] as String? ?? '',
                                  style: const TextStyle(
                                    color: SColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
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
                              data[NotifKeys.body] as String? ?? '',
                              style: SText.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Amount
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

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}
