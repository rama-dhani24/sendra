import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';

class WalletPage extends StatefulWidget {
  final String userId;
  final void Function()? onSendTap;
  final void Function()? onExchangeTap;

  const WalletPage({
    super.key,
    required this.userId,
    this.onSendTap,
    this.onExchangeTap,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  bool _balanceHidden = false;

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

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection(FSKeys.usersCollection)
              .doc(widget.userId)
              .snapshots(),
          builder: (ctx, snap) {
            final data = snap.data?.data() as Map<String, dynamic>?;
            final tzs = (data?[FSKeys.balanceTzs] as num?)?.toDouble() ?? 0.0;
            final usdt = (data?[FSKeys.balanceUsdt] as num?)?.toDouble() ?? 0.0;
            final totalTzs = tzs + AppRates.usdtToTzsAmount(usdt);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(totalTzs, tzs, usdt),
                  const SizedBox(height: 24),
                  _buildAssetCards(tzs, usdt, totalTzs),
                  const SizedBox(height: 24),
                  _buildQuickActions(tzs, usdt),
                  const SizedBox(height: 28),
                  _buildPortfolioBar(tzs, usdt, totalTzs),
                  const SizedBox(height: 28),
                  _buildExchangeHistory(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(double totalTzs, double tzs, double usdt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Wallet',
              style: TextStyle(
                color: SColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _balanceHidden = !_balanceHidden),
              child: Icon(
                _balanceHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: SColors.textSub,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Total portfolio value card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: SDecor.balanceCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Portfolio Value',
                style: TextStyle(color: SColors.textSub, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                _balanceHidden
                    ? 'TZS ••••••'
                    : 'TZS ${Validators.formatNumber(totalTzs)}',
                style: const TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _balanceHidden
                    ? '≈ •••••• USDT'
                    : '≈ ${Validators.formatUsdt(AppRates.tzsToUsdt(totalTzs))} USDT',
                style: const TextStyle(color: SColors.gold, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Asset cards ────────────────────────────────────────────────────────────
  Widget _buildAssetCards(double tzs, double usdt, double totalTzs) {
    final tzsShare = totalTzs > 0 ? (tzs / totalTzs * 100) : 0.0;
    final usdtShare = totalTzs > 0
        ? (AppRates.usdtToTzsAmount(usdt) / totalTzs * 100)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assets',
          style: TextStyle(
            color: SColors.textSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AssetCard(
                flag: '🇹🇿',
                currency: 'TZS',
                name: 'Tanzanian Shilling',
                balance: _balanceHidden
                    ? '••••••'
                    : Validators.formatNumber(tzs),
                prefix: 'TZS',
                equivalent: _balanceHidden
                    ? '≈ •••••• USDT'
                    : '≈ ${Validators.formatUsdt(AppRates.tzsToUsdt(tzs))} USDT',
                share: tzsShare,
                color: SColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AssetCard(
                flag: '🔷',
                currency: 'USDT',
                name: 'Tether USD',
                balance: _balanceHidden
                    ? '••••••'
                    : Validators.formatUsdt(usdt),
                prefix: '',
                suffix: ' USDT',
                equivalent: _balanceHidden
                    ? '≈ TZS ••••••'
                    : '≈ TZS ${Validators.formatNumber(AppRates.usdtToTzsAmount(usdt))}',
                share: usdtShare,
                color: SColors.gold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(double tzs, double usdt) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.send_rounded,
            label: 'Send',
            color: SColors.gold,
            onTap: widget.onSendTap ?? () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Exchange',
            color: SColors.green,
            onTap: widget.onExchangeTap ?? () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.qr_code_rounded,
            label: 'Receive',
            color: SColors.textSub,
            onTap: () => _showReceiveSheet(),
          ),
        ),
      ],
    );
  }

  void _showReceiveSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiveSheet(userId: widget.userId),
    );
  }

  // ── Portfolio bar ──────────────────────────────────────────────────────────
  Widget _buildPortfolioBar(double tzs, double usdt, double totalTzs) {
    final tzsValue = tzs;
    final usdtValue = AppRates.usdtToTzsAmount(usdt);
    final tzsRatio = totalTzs > 0 ? tzsValue / totalTzs : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portfolio Breakdown',
          style: TextStyle(
            color: SColors.textSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: SDecor.card,
          child: Column(
            children: [
              // Stacked bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: [
                      Flexible(
                        flex: (tzsRatio * 100).round(),
                        child: Container(color: SColors.green),
                      ),
                      Flexible(
                        flex: ((1 - tzsRatio) * 100).round(),
                        child: Container(color: SColors.gold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _barLegend(
                    '🇹🇿',
                    'TZS',
                    '${(tzsRatio * 100).toStringAsFixed(1)}%',
                    SColors.green,
                  ),
                  const Spacer(),
                  _barLegend(
                    '🔷',
                    'USDT',
                    '${((1 - tzsRatio) * 100).toStringAsFixed(1)}%',
                    SColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: SColors.navyBorder),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TZS value',
                    style: TextStyle(color: SColors.textSub, fontSize: 12),
                  ),
                  Text(
                    _balanceHidden
                        ? '••••••'
                        : 'TZS ${Validators.formatNumber(tzsValue)}',
                    style: const TextStyle(
                      color: SColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'USDT value (in TZS)',
                    style: TextStyle(color: SColors.textSub, fontSize: 12),
                  ),
                  Text(
                    _balanceHidden
                        ? '••••••'
                        : 'TZS ${Validators.formatNumber(usdtValue)}',
                    style: const TextStyle(
                      color: SColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _barLegend(String flag, String label, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$flag $label',
          style: const TextStyle(color: SColors.textSub, fontSize: 12),
        ),
        const SizedBox(width: 6),
        Text(
          pct,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Exchange history ───────────────────────────────────────────────────────
  Widget _buildExchangeHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exchange History',
          style: TextStyle(
            color: SColors.textSub,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(FSKeys.exchangesCollection)
              .where(ExKeys.userId, isEqualTo: widget.userId)
              .orderBy(ExKeys.createdAt, descending: true)
              .limit(10)
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
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: SDecor.card,
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: SColors.textDim,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text('No exchanges yet', style: SText.caption),
                      const SizedBox(height: 4),
                      Text('Tap Exchange to get started.', style: SText.tiny),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data()! as Map<String, dynamic>;
                final direction = data[ExKeys.direction] as String? ?? '';
                final isBuy = direction == 'buy_usdt';
                final fromAmt =
                    (data[ExKeys.fromAmount] as num?)?.toDouble() ?? 0;
                final toAmt = (data[ExKeys.toAmount] as num?)?.toDouble() ?? 0;
                final fee = (data[ExKeys.feeTzs] as num?)?.toDouble() ?? 0;
                final fromCur = data[ExKeys.fromCurrency] as String? ?? '';
                final toCur = data[ExKeys.toCurrency] as String? ?? '';
                final ts = data[ExKeys.createdAt] as Timestamp?;
                final dt = ts?.toDate() ?? DateTime.now();
                final flag = AppRates.currencyFlags[fromCur] ?? '';
                final toFlag = AppRates.currencyFlags[toCur] ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: SDecor.card,
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isBuy
                                ? SColors.gold.withOpacity(0.10)
                                : SColors.green.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              isBuy ? '🔷' : '🇹🇿',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBuy ? 'Bought USDT' : 'Sold USDT',
                                style: const TextStyle(
                                  color: SColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$flag ${_fmtAmt(fromAmt, fromCur)} → $toFlag ${_fmtAmt(toAmt, toCur)}',
                                style: SText.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(_fmtDate(dt), style: SText.tiny),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isBuy
                                  ? '+${Validators.formatUsdt(toAmt)} USDT'
                                  : '+TZS ${Validators.formatNumber(toAmt)}',
                              style: TextStyle(
                                color: isBuy ? SColors.gold : SColors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Fee: TZS ${Validators.formatNumber(fee)}',
                              style: const TextStyle(
                                color: SColors.textDim,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  String _fmtAmt(double v, String currency) {
    if (currency == 'USDT') return Validators.formatUsdt(v);
    return Validators.formatNumber(v);
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (d == today) return 'Today, $h:$m';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday, $h:$m';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Asset card ────────────────────────────────────────────────────────────
class _AssetCard extends StatelessWidget {
  final String flag;
  final String currency;
  final String name;
  final String balance;
  final String prefix;
  final String suffix;
  final String equivalent;
  final double share;
  final Color color;

  const _AssetCard({
    required this.flag,
    required this.currency,
    required this.name,
    required this.balance,
    this.prefix = '',
    this.suffix = '',
    required this.equivalent,
    required this.share,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SColors.navyLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                currency,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${share.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(color: SColors.textDim, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            '$prefix$balance$suffix',
            style: const TextStyle(
              color: SColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            equivalent,
            style: const TextStyle(color: SColors.textSub, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Action button ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Receive sheet ─────────────────────────────────────────────────────────
class _ReceiveSheet extends StatelessWidget {
  final String userId;
  const _ReceiveSheet({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(userId)
          .get(),
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final accNum = data?[FSKeys.accNumber] as String? ?? '—';
        final name = data?[FSKeys.fullName] as String? ?? '—';

        return Container(
          decoration: const BoxDecoration(
            color: SColors.navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 24),
              const Text(
                'Receive Money',
                style: TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share your Sendra ID to receive money.',
                style: TextStyle(color: SColors.textSub, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Big Sendra ID display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: SDecor.balanceCard,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [SColors.gold, SColors.goldDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
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
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: SColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sendra ID',
                      style: TextStyle(color: SColors.textDim, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      accNum,
                      style: const TextStyle(
                        color: SColors.gold,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Sendra ID $accNum copied',
                          style: const TextStyle(color: SColors.navy),
                        ),
                        backgroundColor: SColors.gold,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
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
            ],
          ),
        );
      },
    );
  }
}
