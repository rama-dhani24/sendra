import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
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

  // ── Change PIN flow ────────────────────────────────────────────────────────
  void _showChangePinSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePinSheet(userId: widget.userId),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  void _logout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: SColors.navyCard,
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
              const Text(
                'Log Out',
                style: TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to log out of your Sendra account?',
                style: TextStyle(color: SColors.textSub, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: SColors.navyLight,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: SColors.textSub, fontSize: 14),
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
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageTitle(),
              const SizedBox(height: 24),
              _buildAvatarCard(),
              const SizedBox(height: 20),
              _buildInfoSection(),
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildActionsSection(),
              const SizedBox(height: 20),
              _buildDangerSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return const Text(
      'Profile',
      style: TextStyle(
        color: SColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ── Avatar + name card ─────────────────────────────────────────────────────
  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: SDecor.balanceCard,
      child: Row(
        children: [
          // Avatar circle
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
                  style: const TextStyle(
                    color: SColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account info ───────────────────────────────────────────────────────────
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Account Information'),
        const SizedBox(height: 12),
        Container(
          decoration: SDecor.card,
          child: Column(
            children: [
              _infoRow(
                icon: Icons.tag_rounded,
                label: 'Sendra ID',
                value: widget.accNumber,
                copyable: true,
              ),
              _divider(),
              _infoRow(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: widget.phone.isEmpty ? '—' : '+255 ${widget.phone}',
              ),
              _divider(),
              _infoRow(
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: widget.userName,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Activity Summary'),
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

            double totalSent = 0;
            double totalReceived = 0;
            int sentCount = 0;
            int receivedCount = 0;

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
                    label: 'Total Sent',
                    value: 'TZS ${Validators.formatNumber(totalSent)}',
                    sub: '$sentCount transactions',
                    color: SColors.red,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    label: 'Total Received',
                    value: 'TZS ${Validators.formatNumber(totalReceived)}',
                    sub: '$receivedCount transactions',
                    color: SColors.green,
                    icon: Icons.arrow_downward_rounded,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SColors.navyLight, width: 1),
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
          Text(
            label,
            style: const TextStyle(color: SColors.textSub, fontSize: 11),
          ),
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
          Text(
            sub,
            style: const TextStyle(color: SColors.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Settings'),
        const SizedBox(height: 12),
        Container(
          decoration: SDecor.card,
          child: Column(
            children: [
              _actionRow(
                icon: Icons.lock_reset_rounded,
                label: 'Change PIN',
                onTap: _showChangePinSheet,
              ),
              _divider(),
              _actionRow(
                icon: Icons.copy_rounded,
                label: 'Copy Sendra ID',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.accNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Sendra ID copied',
                        style: TextStyle(color: SColors.navy),
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
              ),
              _divider(),
              _actionRow(
                icon: Icons.info_outline_rounded,
                label: 'About Sendra',
                onTap: () => _showAbout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Danger zone ────────────────────────────────────────────────────────────
  Widget _buildDangerSection() {
    return Container(
      decoration: BoxDecoration(
        color: SColors.red.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SColors.red.withOpacity(0.2), width: 1),
      ),
      child: _actionRow(
        icon: Icons.logout_rounded,
        label: 'Log Out',
        color: SColors.red,
        onTap: _logout,
        showChevron: false,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: SColors.textSub,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(height: 1, color: SColors.navyLight),
  );

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: SColors.textDim, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: SColors.textDim, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: SColors.textPrimary,
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
                    content: const Text(
                      'Copied',
                      style: TextStyle(color: SColors.navy),
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
              child: const Icon(
                Icons.copy_rounded,
                color: SColors.textDim,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    bool showChevron = true,
  }) {
    final c = color ?? SColors.textPrimary;
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
              const Icon(
                Icons.chevron_right_rounded,
                color: SColors.textDim,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: SColors.navyCard,
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
              const Text(
                'Sendra',
                style: TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fedha zako, Uhuru wako',
                style: TextStyle(color: SColors.gold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cross-border payments for East Africa.\nBuilt with love in Tanzania.',
                style: TextStyle(color: SColors.textSub, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0 · Demo',
                style: const TextStyle(color: SColors.textDim, fontSize: 11),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: SButton.primary,
                  child: const Text('Close', style: SButton.primaryLabel),
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
  const _ChangePinSheet({required this.userId});

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
    setState(() => _error = '');

    final current = _currentCtrl.text.trim();
    final newPin = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (!Validators.isValidPin(current)) {
      setState(() => _error = 'Enter your current 4-digit PIN.');
      return;
    }
    if (!Validators.isValidPin(newPin)) {
      setState(() => _error = 'New PIN must be 4 digits.');
      return;
    }
    if (newPin == current) {
      setState(() => _error = 'New PIN must be different from current PIN.');
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = 'PINs do not match.');
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
          _error = 'Current PIN is incorrect.';
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
          content: const Text(
            'PIN changed successfully',
            style: TextStyle(color: SColors.navy),
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
        _error = 'Network error. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: SColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: SColors.textDim,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change PIN',
              style: TextStyle(
                color: SColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your current PIN and choose a new one.',
              style: TextStyle(color: SColors.textSub, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _pinField(
              controller: _currentCtrl,
              label: 'Current PIN',
              hidden: _currentHidden,
              onToggle: () => setState(() => _currentHidden = !_currentHidden),
            ),
            const SizedBox(height: 14),
            _pinField(
              controller: _newCtrl,
              label: 'New PIN',
              hidden: _newHidden,
              onToggle: () => setState(() => _newHidden = !_newHidden),
            ),
            const SizedBox(height: 14),
            _pinField(
              controller: _confirmCtrl,
              label: 'Confirm New PIN',
              hidden: _confirmHidden,
              onToggle: () => setState(() => _confirmHidden = !_confirmHidden),
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
                    : const Text('Update PIN', style: SButton.primaryLabel),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SText.label),
        const SizedBox(height: 8),
        Container(
          decoration: SDecor.inputField,
          child: TextField(
            controller: controller,
            obscureText: hidden,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 22,
              letterSpacing: 10,
              fontWeight: FontWeight.w700,
            ),
            decoration: SDecor.textInput(
              hint: '••••',
              suffix: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: SColors.textDim,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
