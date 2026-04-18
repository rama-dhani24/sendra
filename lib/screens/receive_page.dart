import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

class ReceivePage extends StatelessWidget {
  final String userId;
  final String userName;
  final String accNumber;

  const ReceivePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.accNumber,
  });

  String get _initials {
    final parts = userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'S';
  }

  void _copyId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: accNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sendra ID $accNumber copied!',
          style: const TextStyle(color: SColors.navy),
        ),
        backgroundColor: SColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          'Receive Money',
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            children: [
              // ── Instruction ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SColors.gold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: SColors.gold,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Share your Sendra ID with the sender. '
                        'They use it to send money directly to your wallet.',
                        style: SText.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Avatar ──────────────────────────────────────────────────
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SColors.gold, SColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: SColors.navy,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                userName,
                style: const TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sendra Account',
                style: TextStyle(color: SColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // ── Big Sendra ID ────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: SDecor.balanceCard,
                child: Column(
                  children: [
                    const Text(
                      'Sendra ID',
                      style: TextStyle(color: SColors.textSub, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Large digit display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: accNumber.split('').map((d) {
                        return Container(
                          width: 44,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: SColors.navy,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: SColors.gold.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                color: SColors.gold,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your unique 5-digit identifier',
                      style: TextStyle(color: SColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Action buttons ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _copyId(context),
                  style: SButton.primary,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: SColors.navy,
                    size: 18,
                  ),
                  label: const Text(
                    'Copy Sendra ID',
                    style: SButton.primaryLabel,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Share via OS share sheet
                    // share_plus: Share.share(...)
                    // For demo just copy
                    _copyId(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SColors.navyLight, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(
                    Icons.share_outlined,
                    color: SColors.textSub,
                    size: 18,
                  ),
                  label: const Text(
                    'Share ID',
                    style: TextStyle(
                      color: SColors.textSub,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── How it works ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: SDecor.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How to receive money',
                      style: TextStyle(
                        color: SColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _step('1', 'Share your 5-digit Sendra ID with the sender'),
                    _step('2', 'They enter your ID on the Send Money screen'),
                    _step('3', 'Your name appears for confirmation'),
                    _step(
                      '4',
                      'Once they confirm, money arrives instantly in TZS',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Recent received ──────────────────────────────────────────
              _RecentReceived(userId: userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: SColors.gold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: SColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: SColors.textSub, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent received transactions ───────────────────────────────────────────
class _RecentReceived extends StatelessWidget {
  final String userId;
  const _RecentReceived({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FSKeys.transactionsCollection)
          .where(TxKeys.receiverId, isEqualTo: userId)
          .orderBy(TxKeys.createdAt, descending: true)
          .limit(5)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recently received',
              style: TextStyle(
                color: SColors.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final amount =
                  (data[TxKeys.receivedTzs] as num?)?.toDouble() ?? 0;
              final from = data[TxKeys.senderName] as String? ?? '';
              final sentAmt =
                  (data[TxKeys.sentAmount] as num?)?.toDouble() ?? 0;
              final sentCur = data[TxKeys.sentCurrency] as String? ?? '';
              final ts = data[TxKeys.createdAt] as Timestamp?;
              final dt = ts?.toDate() ?? DateTime.now();
              final flag = AppRates.currencyFlags[sentCur] ?? '💰';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: SDecor.card,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SColors.green.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(flag, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            from,
                            style: const TextStyle(
                              color: SColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${sentAmt.toStringAsFixed(2)} $sentCur · ${_fmtDate(dt)}',
                            style: SText.tiny,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+TZS ${Validators.formatNumber(amount)}',
                      style: const TextStyle(
                        color: SColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (d == today) return 'Today $h:$m';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday $h:$m';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
