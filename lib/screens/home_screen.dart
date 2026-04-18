import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/services/transaction_service.dart';
import 'package:sendra/screens/send_money_page.dart';
import 'package:sendra/screens/notifications_screen.dart';
import 'package:sendra/screens/profile_page.dart';
import 'package:sendra/screens/exchange_page.dart';
import 'package:sendra/screens/wallet_page.dart';
import 'package:sendra/screens/receive_page.dart';
import 'package:sendra/screens/history_page.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String accNumber;
  final String phone;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.accNumber,
    this.phone = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _balanceHidden = false;

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
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Navigate to send money ─────────────────────────────────────────────────
  void _openSend(double currentBalance) {
    final sender = UserLookup(
      docId: widget.userId,
      fullName: widget.userName,
      accNumber: widget.accNumber,
      phone: '',
      balanceTzs: currentBalance,
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SendMoneyPage(sender: sender)));
  }

  void _openReceive() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceivePage(
          userId: widget.userId,
          userName: widget.userName,
          accNumber: widget.accNumber,
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HistoryPage(userId: widget.userId)),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SColors.bg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FSKeys.usersCollection)
            .doc(widget.userId)
            .snapshots(),
        builder: (ctx, balSnap) {
          final bData = balSnap.data?.data() as Map<String, dynamic>?;
          final liveTzs =
              (bData?[FSKeys.balanceTzs] as num?)?.toDouble() ?? 0.0;

          return IndexedStack(
            index: _navIndex,
            children: [
              _buildHomeTab(),
              const ExchangePage(),
              WalletPage(
                userId: widget.userId,
                onSendTap: () => _openSend(liveTzs),
                onExchangeTap: () => setState(() => _navIndex = 1),
              ),
              ProfilePage(
                userId: widget.userId,
                userName: widget.userName,
                accNumber: widget.accNumber,
                phone: widget.phone,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildNav(),
    );
  }

  // ── Home tab (streamed balance) ────────────────────────────────────────────
  Widget _buildHomeTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FSKeys.usersCollection)
          .doc(widget.userId)
          .snapshots(),
      builder: (ctx, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final balanceTzs =
            (data?[FSKeys.balanceTzs] as num?)?.toDouble() ?? 0.0;

        return FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(balanceTzs)),
                SliverToBoxAdapter(child: _buildBalanceCard(balanceTzs)),
                SliverToBoxAdapter(child: _buildRatesTicker()),
                SliverToBoxAdapter(child: _buildQuickActions(balanceTzs)),
                SliverToBoxAdapter(child: _buildSendPanel(balanceTzs)),
                SliverToBoxAdapter(child: _buildAccNumber()),
                SliverToBoxAdapter(child: _buildTxHeader()),
                SliverToBoxAdapter(child: _buildTxList()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(double balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [SColors.gold, SColors.goldDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _avatar,
                style: const TextStyle(
                  color: SColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.goodMorning, style: SText.caption),
              Text(
                widget.userName,
                style: const TextStyle(
                  color: SColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Notification bell with unread badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FSKeys.notificationsCollection)
                .where(NotifKeys.userId, isEqualTo: widget.userId)
                .where(NotifKeys.isRead, isEqualTo: false)
                .snapshots(),
            builder: (ctx, snap) {
              final unread = snap.data?.docs.length ?? 0;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NotificationsScreen(userId: widget.userId),
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SColors.navyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SColors.navyLight, width: 1),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: SColors.textSub,
                          size: 20,
                        ),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: SColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Balance card ───────────────────────────────────────────────────────────
  Widget _buildBalanceCard(double balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: SDecor.balanceCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(AppStrings.totalBalance, style: SText.caption),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                  child: Icon(
                    _balanceHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: SColors.textSub,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _balanceHidden
                  ? 'TZS ••••••'
                  : 'TZS ${Validators.formatNumber(balance)}',
              style: const TextStyle(
                color: SColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: SColors.navyBorder),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Received',
                  color: SColors.green,
                  userId: widget.userId,
                  type: 'credit',
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Sent',
                  color: SColors.red,
                  userId: widget.userId,
                  type: 'debit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Rates ticker ───────────────────────────────────────────────────────────
  Widget _buildRatesTicker() {
    final tickers = ['GBP', 'USD', 'EUR'].map(AppRates.tickerLabel).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: SDecor.card,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                AppStrings.liveLabel,
                style: TextStyle(
                  color: SColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: tickers
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: SColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions(double balance) {
    final actions = [
      {'label': 'Send', 'icon': Icons.arrow_upward_rounded},
      {'label': 'Receive', 'icon': Icons.arrow_downward_rounded},
      {'label': 'Exchange', 'icon': Icons.swap_horiz_rounded},
      {'label': 'History', 'icon': Icons.receipt_long_rounded},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((a) {
          final isSend = a['label'] == 'Send';
          return GestureDetector(
            onTap: () {
              if (a['label'] == 'Send') _openSend(balance);
              if (a['label'] == 'Exchange') setState(() => _navIndex = 1);
              if (a['label'] == 'Receive') _openReceive();
              if (a['label'] == 'History') _openHistory();
            },
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: isSend
                        ? const LinearGradient(
                            colors: [SColors.gold, SColors.goldDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSend ? null : SColors.navyCard,
                    borderRadius: BorderRadius.circular(18),
                    border: isSend
                        ? null
                        : Border.all(color: SColors.navyLight, width: 1),
                  ),
                  child: Icon(
                    a['icon'] as IconData,
                    color: isSend ? SColors.navy : SColors.textSub,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a['label'] as String,
                  style: TextStyle(
                    color: isSend ? SColors.gold : SColors.textSub,
                    fontSize: 12,
                    fontWeight: isSend ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Send panel ─────────────────────────────────────────────────────────────
  Widget _buildSendPanel(double balance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: GestureDetector(
        onTap: () => _openSend(balance),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: SDecor.goldGlow,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: SColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: SColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.sendMoney, style: SText.sectionTitle),
                  const SizedBox(height: 3),
                  Text(AppStrings.sendSubtitle, style: SText.caption),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: SColors.gold,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Account number strip ───────────────────────────────────────────────────
  Widget _buildAccNumber() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: SDecor.card,
        child: Row(
          children: [
            const Icon(Icons.tag_rounded, color: SColors.textDim, size: 16),
            const SizedBox(width: 8),
            Text('Sendra ID: ', style: SText.tiny),
            Text(
              widget.accNumber,
              style: const TextStyle(
                color: SColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction history header ─────────────────────────────────────────────
  Widget _buildTxHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Text(AppStrings.recentTx, style: SText.sectionTitle),
          const Spacer(),
          Text(
            AppStrings.seeAll,
            style: const TextStyle(color: SColors.gold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Live transaction list from Firestore ───────────────────────────────────
  Widget _buildTxList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FSKeys.transactionsCollection)
          .where(
            Filter.or(
              Filter(TxKeys.senderId, isEqualTo: widget.userId),
              Filter(TxKeys.receiverId, isEqualTo: widget.userId),
            ),
          )
          .orderBy(TxKeys.createdAt, descending: true)
          .limit(10)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(
                color: SColors.gold,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: SDecor.card,
              child: Center(
                child: Text('No transactions yet', style: SText.caption),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            final isSender = data[TxKeys.senderId] == widget.userId;
            final amount = (data[TxKeys.amountTzs] as num?)?.toDouble() ?? 0;
            final name = isSender
                ? data[TxKeys.receiverName] as String? ?? ''
                : data[TxKeys.senderName] as String? ?? '';
            final ts = data[TxKeys.createdAt] as Timestamp?;
            final dt = ts?.toDate() ?? DateTime.now();

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: SDecor.card,
                child: Row(
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
                      child: Icon(
                        isSender
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: isSender ? SColors.red : SColors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: SColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${isSender ? 'Sent' : 'Received'} · ${_fmtDate(dt)}',
                            style: SText.caption,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isSender ? '-' : '+'}TZS ${Validators.formatNumber(amount)}',
                      style: TextStyle(
                        color: isSender ? SColors.red : SColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.currency_exchange_rounded, 'label': 'Exchange'},
      {'icon': Icons.account_balance_wallet_outlined, 'label': 'Wallet'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: SColors.navyCard,
        border: Border(top: BorderSide(color: SColors.navyLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == _navIndex;
              return GestureDetector(
                onTap: () => setState(() => _navIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? SColors.gold.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i]['icon'] as IconData,
                        color: active ? SColors.gold : SColors.textDim,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i]['label'] as String,
                        style: TextStyle(
                          color: active ? SColors.gold : SColors.textDim,
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    if (d == today) return 'Today, $h:$min';
    if (d == today.subtract(const Duration(days: 1)))
      return 'Yesterday, $h:$min';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Stat chip (reads live from Firestore) ─────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String userId;
  final String type; // 'credit' | 'debit'

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.userId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FSKeys.notificationsCollection)
            .where(NotifKeys.userId, isEqualTo: userId)
            .where(NotifKeys.type, isEqualTo: type)
            .snapshots(),
        builder: (ctx, snap) {
          final docs = snap.data?.docs ?? [];
          final total = docs.fold<double>(0, (sum, d) {
            final raw = (d.data()! as Map<String, dynamic>)[NotifKeys.amount];
            final val = (raw as num?)?.toDouble() ?? 0.0;
            return sum + val;
          });
          final prefix = type == 'credit' ? '+' : '-';
          final display = total == 0
              ? 'TZS 0'
              : '$prefix TZS ${Validators.formatNumber(total)}';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: SColors.textSub,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        display,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
