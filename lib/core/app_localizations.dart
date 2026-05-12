import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('en'));
  }

  static const delegate = _AppLocalizationsDelegate();
  static const supportedLocales = [Locale('en'), Locale('sw')];

  bool get isSwahili => locale.languageCode == 'sw';

  // ── General ───────────────────────────────────────────────────────────────
  String get appName => 'Sendra';
  String get tagline =>
      isSwahili ? 'Fedha zako, Uhuru wako' : 'Your Money, Your Freedom';
  String get loading => isSwahili ? 'Inapakia...' : 'Loading...';
  String get cancel => isSwahili ? 'Ghairi' : 'Cancel';
  String get confirm => isSwahili ? 'Thibitisha' : 'Confirm';
  String get ok => 'OK';
  String get comingSoon => isSwahili ? 'Inakuja Hivi Karibuni' : 'Coming Soon';
  String get copied => isSwahili ? 'Imenakiliwa!' : 'Copied!';
  String get copyId =>
      isSwahili ? 'Nakili Nambari ya Sendra' : 'Copy Sendra ID';

  // ── Auth ──────────────────────────────────────────────────────────────────
  String get welcomeBack => isSwahili ? 'Karibu Tena' : 'Welcome back';
  String get loginSubtitle => isSwahili
      ? 'Ingia na nambari yako ya simu na PIN.'
      : 'Log in with your phone number and PIN.';
  String get phoneNumber => isSwahili ? 'Nambari ya Simu' : 'Phone Number';
  String get pin => 'PIN';
  String get logIn => isSwahili ? 'Ingia' : 'Log In';
  String get signUp => isSwahili ? 'Jiandikishe' : 'Sign Up';
  String get noAccount =>
      isSwahili ? 'Huna akaunti? ' : "Don't have an account? ";
  String get alreadyHave =>
      isSwahili ? 'Una akaunti? ' : 'Already have an account? ';
  String get loggingIn => isSwahili ? 'Inaingia...' : 'Logging you in...';
  String get incorrectPin => isSwahili
      ? 'PIN si sahihi. Jaribu tena.'
      : 'Incorrect PIN. Please try again.';
  String get accountNotFound => isSwahili
      ? 'Akaunti haikupatikana.'
      : 'No account found with this phone number.';
  String get loginFailed => isSwahili
      ? 'Imeshindwa kuingia. Jaribu tena.'
      : 'Login failed. Please try again.';
  String get sessionExpired => isSwahili
      ? 'Kipindi kimekwisha. Tafadhali ingia tena.'
      : 'Session expired. Please log in again.';

  // ── Sign Up ───────────────────────────────────────────────────────────────
  String get step1Title =>
      isSwahili ? 'Taarifa Binafsi' : 'Personal Information';
  String get step2Title => isSwahili ? 'Unda PIN Yako' : 'Create Your PIN';
  String get firstName => isSwahili ? 'Jina la Kwanza' : 'First Name';
  String get lastName => isSwahili ? 'Jina la Familia' : 'Last Name';
  String get createPin => isSwahili ? 'Unda PIN' : 'Create PIN';
  String get confirmPin => isSwahili ? 'Thibitisha PIN' : 'Confirm PIN';
  String get createAccount => isSwahili ? 'Unda Akaunti' : 'Create Account';
  String get accountCreated =>
      isSwahili ? 'Akaunti Imeundwa!' : 'Account Created!';
  String get yourSendraId =>
      isSwahili ? 'Nambari yako ya Sendra' : 'Your Sendra ID';
  String get goToLogin => isSwahili ? 'Nenda Kuingia' : 'Go to Login';
  String get pinsMustMatch =>
      isSwahili ? 'PIN hazifanani.' : 'PINs do not match.';
  String get pinMust4Digits => isSwahili
      ? 'PIN lazima iwe na tarakimu 4.'
      : 'PIN must be exactly 4 digits.';
  String get phoneRegistered => isSwahili
      ? 'Nambari hii imesajiliwa tayari.'
      : 'This phone number is already registered.';

  // ── Home ──────────────────────────────────────────────────────────────────
  String get goodMorning => isSwahili ? 'Habari za asubuhi,' : 'Good morning,';
  String get totalBalance => isSwahili ? 'Jumla ya Salio' : 'Total Balance';
  String get recentTx =>
      isSwahili ? 'Miamala ya Hivi Karibuni' : 'Recent Transactions';
  String get seeAll => isSwahili ? 'Ona Yote' : 'See all';
  String get liveLabel => 'LIVE';
  String get noTransactions =>
      isSwahili ? 'Hakuna miamala bado' : 'No transactions yet';

  // ── Quick Actions ─────────────────────────────────────────────────────────
  String get send => isSwahili ? 'Tuma' : 'Send';
  String get receive => isSwahili ? 'Pokea' : 'Receive';
  String get withdraw => isSwahili ? 'Toa' : 'Withdraw';
  String get history => isSwahili ? 'Historia' : 'History';
  String get bank => isSwahili ? 'Benki' : 'Bank';
  String get bills => isSwahili ? 'Bili' : 'Bills';
  String get airtime => isSwahili ? 'Muda wa Hewa' : 'Airtime';
  String get exchange => isSwahili ? 'Ubadilishaji' : 'Exchange';

  // ── Send Money ────────────────────────────────────────────────────────────
  String get sendMoney => isSwahili ? 'Tuma Pesa' : 'Send Money';
  String get sendSubtitle => 'GBP · USD · EUR · USDT → TZS';
  String get recipientId =>
      isSwahili ? 'Nambari ya Sendra ya Mpokeaji' : 'Recipient Sendra ID';
  String get sendingCurrency =>
      isSwahili ? 'Sarafu ya Kutuma' : 'Sending Currency';
  String get amount => isSwahili ? 'Kiasi' : 'Amount';
  String get findRecipient => isSwahili ? 'Tafuta Mpokeaji' : 'Find Recipient';
  String get proceedConfirm =>
      isSwahili ? 'Endelea Kuthibitisha' : 'Proceed to Confirm';
  String get authorizeTransaction =>
      isSwahili ? 'Idhini Muamala' : 'Authorize Transaction';
  String get availableBalance =>
      isSwahili ? 'Salio Linalopatikana' : 'Available Balance';
  String get recipientGets => isSwahili ? 'Mpokeaji Anapata' : 'Recipient gets';
  String get totalDeducted => isSwahili ? 'Jumla Iliyokatwa' : 'Total deducted';
  String get transactionFee =>
      isSwahili ? 'Ada ya Muamala (1%)' : 'Transaction fee (1%)';
  String get irreversibleWarn => isSwahili
      ? 'Angalia kwa makini. Muamala huu hauwezi kurejeshwa.'
      : 'Review carefully. This transaction cannot be reversed.';
  String get insufficientBal =>
      isSwahili ? 'Salio haitoshi.' : 'Insufficient balance.';

  // ── Receipt ───────────────────────────────────────────────────────────────
  String get transactionSuccessful =>
      isSwahili ? 'Muamala Umefanikiwa' : 'Transaction Successful';
  String get receipt => isSwahili ? 'Risiti' : 'Receipt';
  String get completed => isSwahili ? 'Imekamilika' : 'Completed';
  String get transactionId =>
      isSwahili ? 'Nambari ya Muamala' : 'Transaction ID';
  String get youSent => isSwahili ? 'Ulituma' : 'You sent';
  String get rateUsed => isSwahili ? 'Kiwango Kilichotumika' : 'Rate used';
  String get totalCostSender =>
      isSwahili ? 'Jumla ya Gharama' : 'Total cost to sender';
  String get recipientReceived =>
      isSwahili ? 'Mpokeaji Alipokea' : 'Recipient received';
  String get download => isSwahili ? 'Pakua' : 'Download';
  String get share => isSwahili ? 'Shiriki' : 'Share';
  String get backToHome => isSwahili ? 'Rudi Nyumbani' : 'Back to Home';
  String get poweredBy => isSwahili
      ? 'Inaendeshwa na Sendra · Fedha zako, Uhuru wako'
      : 'Powered by Sendra · Your Money, Your Freedom';

  // ── History ───────────────────────────────────────────────────────────────
  String get transactionHistory =>
      isSwahili ? 'Historia ya Miamala' : 'Transaction History';
  String get all => isSwahili ? 'Yote' : 'All';
  String get sent => isSwahili ? 'Zilizotumwa' : 'Sent';
  String get received => isSwahili ? 'Zilizopokelewa' : 'Received';
  String get totalSent => isSwahili ? 'Jumla Iliyotumwa' : 'Total Sent';
  String get totalReceived =>
      isSwahili ? 'Jumla Iliyopokelewa' : 'Total Received';
  String get today => isSwahili ? 'Leo' : 'Today';
  String get yesterday => isSwahili ? 'Jana' : 'Yesterday';
  String get txWillAppear => isSwahili
      ? 'Miamala yako itaonekana hapa.'
      : 'Your transactions will appear here.';

  // ── Profile / Settings ────────────────────────────────────────────────────
  String get profile => isSwahili ? 'Wasifu' : 'Profile';
  String get language => isSwahili ? 'Lugha' : 'Language';
  String get theme => isSwahili ? 'Mandhari' : 'Theme';
  String get darkMode => isSwahili ? 'Hali ya Giza' : 'Dark Mode';
  String get lightMode => isSwahili ? 'Hali ya Mwanga' : 'Light Mode';
  String get systemDefault =>
      isSwahili ? 'Mwongozo wa Mfumo' : 'System Default';
  String get logout => isSwahili ? 'Toka' : 'Log Out';
  String get logoutConfirm => isSwahili
      ? 'Una uhakika unataka kutoka?'
      : 'Are you sure you want to log out?';
  String get sendraId => isSwahili ? 'Nambari ya Sendra' : 'Sendra ID';

  // ── Nav ───────────────────────────────────────────────────────────────────
  String get home => isSwahili ? 'Nyumbani' : 'Home';
  String get navWallet => isSwahili ? 'Mkoba' : 'Wallet';
  String get navProfile => isSwahili ? 'Wasifu' : 'Profile';

  // ── Notifications ─────────────────────────────────────────────────────────
  String get notifications => isSwahili ? 'Arifa' : 'Notifications';
  String get noNotifications => isSwahili ? 'Hakuna arifa' : 'No notifications';
  String get markAllRead =>
      isSwahili ? 'Weka Zote Zimesomwa' : 'Mark all as read';

  // ── Withdraw / Bank / Bills / Airtime ─────────────────────────────────────
  String get withdrawTitle => isSwahili ? 'Toa Pesa' : 'Withdraw';
  String get withdrawalMethod =>
      isSwahili ? 'Njia ya Kutoa' : 'Withdrawal Method';
  String get withdrawNow => isSwahili ? 'Toa Sasa' : 'Withdraw Now';
  String get bankTransfer => isSwahili ? 'Uhamisho wa Benki' : 'Bank Transfer';
  String get selectBank => isSwahili ? 'Chagua Benki' : 'Select Bank';
  String get accountNumber =>
      isSwahili ? 'Nambari ya Akaunti' : 'Account Number';
  String get accountName => isSwahili ? 'Jina la Akaunti' : 'Account Name';
  String get transferNow => isSwahili ? 'Hamisha Sasa' : 'Transfer Now';
  String get payBills => isSwahili ? 'Lipa Bili' : 'Pay Bills';
  String get payNow => isSwahili ? 'Lipa Sasa' : 'Pay Now';
  String get buyAirtime => isSwahili ? 'Nunua Muda wa Hewa' : 'Buy Airtime';
  String get network => isSwahili ? 'Mtandao' : 'Network';
  String get mobileNumber => isSwahili ? 'Nambari ya Simu' : 'Mobile Number';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'sw'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
