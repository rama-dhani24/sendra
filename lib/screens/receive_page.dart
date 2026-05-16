import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';

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

  void _copyId(BuildContext context, AppLocalizations l) {
    Clipboard.setData(ClipboardData(text: accNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sendra ID $accNumber ${l.isSwahili ? 'imenakiliwa!' : 'copied!'}',
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
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final digitBg = isDark ? SColors.navy : SColors.lightBg;
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
          l.isSwahili ? 'Pokea Pesa' : 'Receive Money',
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            children: [
              // ── Instruction banner ───────────────────────────────────────
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
                        l.isSwahili
                            ? 'Shiriki Sendra ID yako na mtumaji. '
                                  'Watatumia kutuma pesa moja kwa moja kwenye mkoba wako.'
                            : 'Share your Sendra ID with the sender. '
                                  'They use it to send money directly to your wallet.',
                        style: TextStyle(color: textSub, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Avatar ───────────────────────────────────────────────────
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
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.isSwahili ? 'Akaunti ya Sendra' : 'Sendra Account',
                style: TextStyle(color: textSub, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // ── Big Sendra ID card ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Text(
                      l.sendraId,
                      style: TextStyle(color: textSub, fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // Digit tiles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: accNumber.split('').map((d) {
                        return Container(
                          width: 44,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: digitBg,
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
                    Text(
                      l.isSwahili
                          ? 'Kitambulisho chako cha kipekee cha tarakimu 5'
                          : 'Your unique 5-digit identifier',
                      style: TextStyle(color: textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Copy button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _copyId(context, l),
                  style: SButton.primary,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: SColors.navy,
                    size: 18,
                  ),
                  label: Text(l.copyId, style: SButton.primaryLabel),
                ),
              ),
              const SizedBox(height: 12),

              // ── Share button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyId(context, l),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(Icons.share_outlined, color: textSub, size: 18),
                  label: Text(
                    l.isSwahili ? 'Shiriki ID' : 'Share ID',
                    style: TextStyle(
                      color: textSub,
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
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.isSwahili
                          ? 'Jinsi ya kupokea pesa'
                          : 'How to receive money',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _step(
                      '1',
                      l.isSwahili
                          ? 'Shiriki Sendra ID yako ya tarakimu 5 na mtumaji'
                          : 'Share your 5-digit Sendra ID with the sender',
                      textSub,
                    ),
                    _step(
                      '2',
                      l.isSwahili
                          ? 'Wanaingiza ID yako kwenye skrini ya Tuma Pesa'
                          : 'They enter your ID on the Send Money screen',
                      textSub,
                    ),
                    _step(
                      '3',
                      l.isSwahili
                          ? 'Jina lako linaonekana kwa uthibitisho'
                          : 'Your name appears for confirmation',
                      textSub,
                    ),
                    _step(
                      '4',
                      l.isSwahili
                          ? 'Wakithibitisha, pesa inafika mara moja kwa TZS'
                          : 'Once they confirm, money arrives instantly in TZS',
                      textSub,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Recent received ──────────────────────────────────────────
              _RecentReceived(userId: userId, isDark: isDark, l: l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String num, String text, Color textColor) {
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
            child: Text(text, style: TextStyle(color: textColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Recent received transactions ───────────────────────────────────────────
class _RecentReceived extends StatelessWidget {
  final String userId;
  final bool isDark;
  final AppLocalizations l;

  const _RecentReceived({
    required this.userId,
    required this.isDark,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

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
            Text(
              l.isSwahili
                  ? 'Zilizopokelewa hivi karibuni'
                  : 'Recently received',
              style: TextStyle(
                color: textSub,
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
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
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
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${sentAmt.toStringAsFixed(2)} $sentCur · ${_fmtDate(dt, l)}',
                            style: TextStyle(color: textDim, fontSize: 11),
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

  String _fmtDate(DateTime dt, AppLocalizations l) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (d == today) return '${l.today} $h:$m';
    if (d == today.subtract(const Duration(days: 1)))
      return '${l.yesterday} $h:$m';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
