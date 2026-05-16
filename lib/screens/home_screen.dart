import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/core/app_localizations.dart';
import 'package:sendra/screens/transaction_service.dart';
import 'package:sendra/screens/send_money_page.dart';
import 'package:sendra/screens/notifications_screen.dart';
import 'package:sendra/screens/profile_page.dart';
import 'package:sendra/screens/exchange_page.dart';
import 'package:sendra/screens/wallet_page.dart';
import 'package:sendra/screens/receive_page.dart';
import 'package:sendra/screens/history_page.dart';
import 'package:sendra/screens/withdraw_page.dart';
import 'package:sendra/screens/bank_transfer_page.dart';
import 'package:sendra/screens/bills_page.dart';
import 'package:sendra/screens/airtime_page.dart';
import 'package:provider/provider.dart';
import 'package:sendra/providers/app_providers.dart';

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

  // Language toggle: true = English 🇬🇧 (default), false = Swahili 🇹🇿
  bool _isEnglish = true;

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

  // ── Language toggle ───────────────────────────────────────────────────────
  void _toggleLanguage() {
    setState(() => _isEnglish = !_isEnglish);
    context.read<LocaleProvider>().setLocale(
      _isEnglish ? const Locale('en') : const Locale('sw'),
    );
  }

  // ── Theme toggle — switches instantly between dark and light ──────────────
  void _toggleTheme() {
    final provider = context.read<ThemeProvider>();
    provider.setMode(
      provider.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  String get _currentFlag => _isEnglish ? '🇬🇧' : '🇹🇿';

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _openSend(double balance) {
    final sender = UserLookup(
      docId: widget.userId,
      fullName: widget.userName,
      accNumber: widget.accNumber,
      phone: widget.phone,
      balanceTzs: balance,
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SendMoneyPage(sender: sender)));
  }

  void _openReceive() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ReceivePage(
        userId: widget.userId,
        userName: widget.userName,
        accNumber: widget.accNumber,
      ),
    ),
  );

  void _openHistory() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => HistoryPage(userId: widget.userId)));

  void _openWithdraw(double balance) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => WithdrawPage(userId: widget.userId, balanceTzs: balance),
    ),
  );

  void _openBankTransfer(double balance) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          BankTransferPage(userId: widget.userId, balanceTzs: balance),
    ),
  );

  void _openBills(double balance) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BillsPage(userId: widget.userId, balanceTzs: balance),
    ),
  );

  void _openAirtime(double balance) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AirtimePage(userId: widget.userId, balanceTzs: balance),
    ),
  );

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? SColors.bg : SColors.lightBg;
    final navCardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final navBorderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final inactiveLabelColor = isDark ? SColors.textDim : SColors.lightTextDim;
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: bgColor,
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
              _buildHomeTab(isDark),
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
      bottomNavigationBar: _buildNav(
        l,
        navCardColor,
        navBorderColor,
        SColors.gold,
        inactiveLabelColor,
      ),
    );
  }

  // ── Home tab ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab(bool isDark) {
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
                SliverToBoxAdapter(child: _buildHeader(isDark)),
                SliverToBoxAdapter(
                  child: _buildBalanceCard(balanceTzs, isDark),
                ),
                SliverToBoxAdapter(child: _buildRatesTicker(isDark)),
                SliverToBoxAdapter(
                  child: _buildQuickActions(balanceTzs, isDark),
                ),
                SliverToBoxAdapter(child: _buildSendPanel(balanceTzs, isDark)),
                SliverToBoxAdapter(child: _buildAccNumber(isDark)),
                SliverToBoxAdapter(child: _buildTxHeader(isDark)),
                SliverToBoxAdapter(child: _buildTxList(isDark)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final l = AppLocalizations.of(context);

    // Read current theme mode from provider (no setState needed — provider
    // rebuilds the tree automatically when toggled)
    final themeMode = context.watch<ThemeProvider>().mode;
    final isCurrentlyDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // ── Avatar ────────────────────────────────────────────────────────
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
              Text(
                l.goodMorning,
                style: TextStyle(color: textSub, fontSize: 13),
              ),
              Text(
                widget.userName,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),

          // ── Flag language toggle ──────────────────────────────────────────
          GestureDetector(
            onTap: _toggleLanguage,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Container(
                key: ValueKey<bool>(_isEnglish),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SColors.gold.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _currentFlag,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Instant theme toggle (dark ↔ light) ───────────────────────────
          GestureDetector(
            onTap: _toggleTheme,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Container(
                key: ValueKey<bool>(isCurrentlyDark),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(
                  // Shows what you'll switch TO (sun = currently dark, moon = currently light)
                  isCurrentlyDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: isCurrentlyDark ? SColors.gold : textSub,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // ── Notifications ─────────────────────────────────────────────────
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.notifications_outlined,
                          color: textSub,
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

  // ── Balance card ──────────────────────────────────────────────────────────
  Widget _buildBalanceCard(double balance, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final dividerColor = isDark ? SColors.navyBorder : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l.totalBalance,
                  style: TextStyle(color: textSub, fontSize: 13),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                  child: Icon(
                    _balanceHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textSub,
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
              style: TextStyle(
                color: textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: dividerColor),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  icon: Icons.arrow_downward_rounded,
                  label: _isEnglish ? 'Received' : 'Zilizopokelewa',
                  color: SColors.green,
                  userId: widget.userId,
                  type: 'credit',
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.arrow_upward_rounded,
                  label: _isEnglish ? 'Sent' : 'Zilizotumwa',
                  color: SColors.red,
                  userId: widget.userId,
                  type: 'debit',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Rates ticker ──────────────────────────────────────────────────────────
  Widget _buildRatesTicker(bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final tickers = ['GBP', 'USD', 'EUR'].map(AppRates.tickerLabel).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: SColors.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LIVE',
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
                            style: TextStyle(
                              color: textPrimary,
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

  // ── Quick actions ─────────────────────────────────────────────────────────
  Widget _buildQuickActions(double balance, bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    final row1 = [
      {
        'labelEn': 'Send',
        'labelSw': 'Tuma',
        'icon': Icons.send_rounded,
        'primary': true,
      },
      {
        'labelEn': 'Receive',
        'labelSw': 'Pokea',
        'icon': Icons.arrow_downward_rounded,
        'primary': false,
      },
      {
        'labelEn': 'Withdraw',
        'labelSw': 'Toa',
        'icon': Icons.output_rounded,
        'primary': false,
      },
      {
        'labelEn': 'History',
        'labelSw': 'Historia',
        'icon': Icons.receipt_long_rounded,
        'primary': false,
      },
    ];
    final row2 = [
      {
        'labelEn': 'Bank',
        'labelSw': 'Benki',
        'icon': Icons.account_balance_outlined,
        'primary': false,
      },
      {
        'labelEn': 'Bills',
        'labelSw': 'Bili',
        'icon': Icons.receipt_outlined,
        'primary': false,
      },
      {
        'labelEn': 'Airtime',
        'labelSw': 'Muda wa Hewa',
        'icon': Icons.phone_android_outlined,
        'primary': false,
      },
      {
        'labelEn': 'Exchange',
        'labelSw': 'Ubadilishaji',
        'icon': Icons.swap_horiz_rounded,
        'primary': false,
      },
    ];

    Widget actionBtn(Map<String, dynamic> a) {
      final isPrimary = a['primary'] as bool;
      final label = _isEnglish
          ? a['labelEn'] as String
          : a['labelSw'] as String;
      final key = a['labelEn'] as String;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            switch (key) {
              case 'Send':
                _openSend(balance);
                break;
              case 'Receive':
                _openReceive();
                break;
              case 'Withdraw':
                _openWithdraw(balance);
                break;
              case 'History':
                _openHistory();
                break;
              case 'Bank':
                _openBankTransfer(balance);
                break;
              case 'Bills':
                _openBills(balance);
                break;
              case 'Airtime':
                _openAirtime(balance);
                break;
              case 'Exchange':
                setState(() => _navIndex = 1);
                break;
            }
          },
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: isPrimary
                      ? const LinearGradient(
                          colors: [SColors.gold, SColors.goldDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isPrimary ? null : cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: isPrimary
                      ? null
                      : Border.all(color: borderColor, width: 1),
                ),
                child: Icon(
                  a['icon'] as IconData,
                  color: isPrimary ? SColors.navy : textSub,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? SColors.gold : textSub,
                  fontSize: 11,
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Row(children: row1.map(actionBtn).toList()),
          const SizedBox(height: 16),
          Row(children: row2.map(actionBtn).toList()),
        ],
      ),
    );
  }

  // ── Send panel ────────────────────────────────────────────────────────────
  Widget _buildSendPanel(double balance, bool isDark) {
    final l = AppLocalizations.of(context);
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: GestureDetector(
        onTap: () => _openSend(balance),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4A843)),
          ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.sendMoney,
                      style: TextStyle(
                        color: isDark
                            ? SColors.textPrimary
                            : SColors.lightTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.sendSubtitle,
                      style: TextStyle(color: textSub, fontSize: 13),
                    ),
                  ],
                ),
              ),
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

  // ── Account number ────────────────────────────────────────────────────────
  Widget _buildAccNumber(bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textDim = isDark ? SColors.textDim : SColors.lightTextDim;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.tag_rounded, color: textDim, size: 16),
            const SizedBox(width: 8),
            Text(
              '${l.sendraId}: ',
              style: TextStyle(color: textDim, fontSize: 11),
            ),
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

  // ── Tx header ─────────────────────────────────────────────────────────────
  Widget _buildTxHeader(bool isDark) {
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        children: [
          Text(
            l.recentTx,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openHistory,
            child: Text(
              l.seeAll,
              style: const TextStyle(color: SColors.gold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tx list ───────────────────────────────────────────────────────────────
  Widget _buildTxList(bool isDark) {
    final cardColor = isDark ? SColors.navyCard : SColors.lightCard;
    final borderColor = isDark ? SColors.navyLight : SColors.lightBorder;
    final textPrimary = isDark ? SColors.textPrimary : SColors.lightTextPrimary;
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;
    final l = AppLocalizations.of(context);

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
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  l.noTransactions,
                  style: TextStyle(color: textSub, fontSize: 13),
                ),
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
            final sentCur = data[TxKeys.sentCurrency] as String? ?? 'TZS';
            final flag = AppRates.currencyFlags[sentCur] ?? '💰';

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
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
                            name,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${isSender ? (_isEnglish ? 'Sent' : 'Imetumwa') : (_isEnglish ? 'Received' : 'Imepokelewa')} · ${_fmtDate(dt)}',
                            style: TextStyle(color: textSub, fontSize: 13),
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

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildNav(
    AppLocalizations l,
    Color cardColor,
    Color borderColor,
    Color activeColor,
    Color inactiveColor,
  ) {
    final items = [
      {'icon': Icons.home_rounded, 'label': l.home},
      {'icon': Icons.currency_exchange_rounded, 'label': l.exchange},
      {'icon': Icons.account_balance_wallet_outlined, 'label': l.navWallet},
      {'icon': Icons.person_outline_rounded, 'label': l.navProfile},
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == _navIndex;
              final label = items[i]['label'] as String;
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
                        color: active ? SColors.gold : inactiveColor,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          color: active ? activeColor : inactiveColor,
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
    final m = dt.minute.toString().padLeft(2, '0');
    if (d == today) return '${_isEnglish ? 'Today' : 'Leo'}, $h:$m';
    if (d == today.subtract(const Duration(days: 1)))
      return '${_isEnglish ? 'Yesterday' : 'Jana'}, $h:$m';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label, userId, type;
  final Color color;
  final bool isDark;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.userId,
    required this.type,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSub = isDark ? SColors.textSub : SColors.lightTextSub;

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FSKeys.notificationsCollection)
            .where(NotifKeys.userId, isEqualTo: userId)
            .where(NotifKeys.type, isEqualTo: type)
            .snapshots(),
        builder: (ctx, snap) {
          final total = (snap.data?.docs ?? []).fold<double>(0, (sum, d) {
            final raw = (d.data()! as Map<String, dynamic>)[NotifKeys.amount];
            return sum + ((raw as num?)?.toDouble() ?? 0.0);
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
                        style: TextStyle(color: textSub, fontSize: 10),
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
