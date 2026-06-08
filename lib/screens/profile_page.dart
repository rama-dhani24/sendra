import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';
import 'package:sendra/screens/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String accNumber;
  final String phone;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.accNumber,
    required this.phone,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  String get _avatar {
    final parts = widget.userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : 'U';
  }

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

  void _showChangePinSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePinSheet(userId: widget.userId, isDark: isDark),
    );
  }

  void _logout(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: SColors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: SColors.red,
                  size: 26,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.logout,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.logoutConfirm,
                style: TextStyle(color: textSub, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l.cancel,
                        style: TextStyle(color: textSub, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (_) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SColors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l.logout,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.profile,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _buildAvatarCard(isDark),
              const SizedBox(height: 20),
              _buildInfoSection(l, isDark),
              const SizedBox(height: 20),
              _buildStatsSection(l, isDark),
              const SizedBox(height: 20),
              _buildActionsSection(l, isDark),
              const SizedBox(height: 20),
              _buildDangerSection(l, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar card ────────────────────────────────────────────────────────────
  Widget _buildAvatarCard(bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SColors.gold, SColors.goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _avatar,
                style: const TextStyle(
                  color: SColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SColors.gold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Sendra Member',
                    style: TextStyle(
                      color: SColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account info ───────────────────────────────────────────────────────────
  Widget _buildInfoSection(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          l.isSwahili ? 'Taarifa za Akaunti' : 'Account Information',
          textSub,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _infoRow(
                icon: Icons.tag_rounded,
                label: l.sendraId,
                value: widget.accNumber,
                copyable: true,
                isDark: isDark,
              ),
              _divider(borderColor),
              _infoRow(
                icon: Icons.phone_outlined,
                label: l.phoneNumber,
                value: widget.phone.isEmpty ? '—' : '+ ${widget.phone}',
                isDark: isDark,
              ),
              _divider(borderColor),
              _infoRow(
                icon: Icons.person_outline_rounded,
                label: l.isSwahili ? 'Jina Kamili' : 'Full Name',
                value: widget.userName,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStatsSection(AppLocalizations l, bool isDark) {
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          l.isSwahili ? 'Muhtasari wa Shughuli' : 'Activity Summary',
          textSub,
        ),
        const SizedBox(height: 12),
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
            final docs = snap.data?.docs ?? [];
            double totalSent = 0, totalReceived = 0;
            int sentCount = 0, receivedCount = 0;

            for (final doc in docs) {
              final data = doc.data()! as Map<String, dynamic>;
              final isSender = data[TxKeys.senderId] == widget.userId;
              final tzs = (data[TxKeys.amountTzs] as num?)?.toDouble() ?? 0;
              if (isSender) {
                totalSent += tzs;
                sentCount++;
              } else {
                totalReceived += tzs;
                receivedCount++;
              }
            }

            return Row(
              children: [
                Expanded(
                  child: _statCard(
                    label: l.totalSent,
                    value: 'TZS ${Validators.formatNumber(totalSent)}',
                    sub: l.isSwahili
                        ? '$sentCount miamala'
                        : '$sentCount transactions',
                    color: SColors.red,
                    icon: Icons.arrow_upward_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: l.totalReceived,
                    value: 'TZS ${Validators.formatNumber(totalReceived)}',
                    sub: l.isSwahili
                        ? '$receivedCount miamala'
                        : '$receivedCount transactions',
                    color: SColors.green,
                    icon: Icons.arrow_downward_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: textDim, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: textDim, fontSize: 10)),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Widget _buildActionsSection(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(l.isSwahili ? 'Mipangilio' : 'Settings', textSub),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              _actionRow(
                icon: Icons.lock_reset_rounded,
                label: l.isSwahili ? 'Badilisha PIN' : 'Change PIN',
                onTap: () => _showChangePinSheet(isDark),
                isDark: isDark,
              ),
              _divider(borderColor),
              _actionRow(
                icon: Icons.copy_rounded,
                label: l.copyId,
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.accNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l.copied,
                        style: const TextStyle(color: SColors.navy),
                      ),
                      backgroundColor: SColors.gold,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                isDark: isDark,
              ),
              _divider(borderColor),
              _actionRow(
                icon: Icons.info_outline_rounded,
                label: l.isSwahili ? 'Kuhusu Sendra' : 'About Sendra',
                onTap: () => _showAbout(l, isDark),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Danger zone ────────────────────────────────────────────────────────────
  Widget _buildDangerSection(AppLocalizations l, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: SColors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SColors.red.withOpacity(0.2)),
      ),
      child: _actionRow(
        icon: Icons.logout_rounded,
        label: l.logout,
        color: SColors.red,
        onTap: () => _logout(l, isDark),
        showChevron: false,
        isDark: isDark,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );

  Widget _divider(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(height: 1, color: color),
  );

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
    required bool isDark,
  }) {
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: textDim, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: textDim, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).copied,
                      style: const TextStyle(color: SColors.navy),
                    ),
                    backgroundColor: SColors.gold,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Icon(Icons.copy_rounded, color: textDim, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
    bool showChevron = true,
  }) {
    final c =
        color ?? (isDark ? SColors.textPrimary : SColors.lightTextPrimary);
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color ?? SColors.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right_rounded, color: textDim, size: 18),
          ],
        ),
      ),
    );
  }

  void _showAbout(AppLocalizations l, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SColors.gold, SColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: SColors.navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sendra',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.tagline,
                style: const TextStyle(color: SColors.gold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                l.isSwahili
                    ? 'Malipo ya kimataifa kwa Afrika Mashariki.\nImetengenezwa kwa upendo Tanzania.'
                    : 'Cross-border payments for East Africa.\nBuilt with love in Tanzania.',
                style: TextStyle(color: textSub, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0 · Demo',
                style: TextStyle(color: textDim, fontSize: 11),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: SButton.primary,
                  child: Text(
                    l.isSwahili ? 'Funga' : 'Close',
                    style: SButton.primaryLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Change PIN bottom sheet ───────────────────────────────────────────────
class _ChangePinSheet extends StatefulWidget {
  final String userId;
  final bool isDark;
  const _ChangePinSheet({required this.userId, required this.isDark});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _currentHidden = true;
  bool _newHidden = true;
  bool _confirmHidden = true;
  String _error = '';

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    final l = AppLocalizations.of(context);
    setState(() => _error = '');

    final current = _currentCtrl.text.trim();
    final newPin = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (!Validators.isValidPin(current)) {
      setState(
        () => _error = l.isSwahili
            ? 'Weka PIN yako ya sasa ya tarakimu 4.'
            : 'Enter your current 4-digit PIN.',
      );
      return;
    }
    if (!Validators.isValidPin(newPin)) {
      setState(() => _error = l.pinMust4Digits);
      return;
    }
    if (newPin == current) {
      setState(
        () => _error = l.isSwahili
            ? 'PIN mpya lazima iwe tofauti na ya sasa.'
            : 'New PIN must be different from current PIN.',
      );
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = l.pinsMustMatch);
      return;
    }

    setState(() => _loading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(widget.userId)
          .get();

      if (snap.data()?[FSKeys.pin] != current) {
        setState(() {
          _error = l.isSwahili
              ? 'PIN ya sasa si sahihi.'
              : 'Current PIN is incorrect.';
          _loading = false;
        });
        return;
      }

      await FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(widget.userId)
          .update({FSKeys.pin: newPin});

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.isSwahili ? 'PIN imebadilishwa' : 'PIN changed successfully',
            style: const TextStyle(color: SColors.navy),
          ),
          backgroundColor: SColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (_) {
      setState(() {
        _error = AppLocalizations.of(context).isSwahili
            ? 'Hitilafu ya mtandao. Jaribu tena.'
            : 'Network error. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final sheetBg = isDark ? SColors.navy : SColors.lightBg;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.isSwahili ? 'Badilisha PIN' : 'Change PIN',
              style: TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.isSwahili
                  ? 'Weka PIN yako ya sasa na uchague mpya.'
                  : 'Enter your current PIN and choose a new one.',
              style: TextStyle(color: textSub, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _pinField(
              controller: _currentCtrl,
              label: l.isSwahili ? 'PIN ya Sasa' : 'Current PIN',
              hidden: _currentHidden,
              onToggle: () => setState(() => _currentHidden = !_currentHidden),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _pinField(
              controller: _newCtrl,
              label: l.createPin,
              hidden: _newHidden,
              onToggle: () => setState(() => _newHidden = !_newHidden),
              isDark: isDark,
            ),
            const SizedBox(height: 14),
            _pinField(
              controller: _confirmCtrl,
              label: l.confirmPin,
              hidden: _confirmHidden,
              onToggle: () => setState(() => _confirmHidden = !_confirmHidden),
              isDark: isDark,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 14),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _changePin,
                style: SButton.primary,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: SColors.navy,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        l.isSwahili ? 'Sasisha PIN' : 'Update PIN',
                        style: SButton.primaryLabel,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
            controller: controller,
            obscureText: hidden,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: TextStyle(
              color: textPrimary,
              fontSize: 22,
              letterSpacing: 10,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '••••',
              hintStyle: TextStyle(color: textDim, fontSize: 15),
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textDim,
                    size: 18,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
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
      ],
    );
  }
}
