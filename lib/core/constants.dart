// ─── App constants ─────────────────────────────────────────────────────────
class AppStrings {
  AppStrings._();

  static const appName = 'Sendra';
  static const tagline = 'Fedha zako, Uhuru wako';
  static const logoLetter = 'S';

  static const welcomeBack = 'Welcome back';
  static const loginSubtitle = 'Log in with your phone number and PIN.';
  static const phonePlaceholder = '0779122997';
  static const phoneFormat = 'Format: 0779XXXXXX or 0689XXXXXX';
  static const noAccount = "Don't have an account? ";
  static const signUpLink = 'Sign Up';
  static const logInLink = 'Log In';

  static const step1Title = 'Personal Information';
  static const step2Title = 'Create Your PIN';
  static const step1Sub = 'Enter your details to create your Sendra account.';
  static const step2Sub = 'Your 4-digit PIN will be used to log in.';
  static const alreadyHave = 'Already have an account? ';

  static const goodMorning = 'Good morning,';
  static const totalBalance = 'Total Balance';
  static const liveLabel = 'LIVE';
  static const seeAll = 'See all';
  static const recentTx = 'Recent Transactions';
  static const sendMoney = 'Send Money';
  static const sendSubtitle = 'GBP · USD · EUR · USDT → TZS';
  static const recipientReceives = 'Recipient receives in TZS';
  static const enterAmount = 'Enter amount to see conversion';
  static const spread = 'Spread';
  static const enterAmountBtn = 'Enter Amount';
  static const sendNow = 'Send Now';
}

// ─── Rates ─────────────────────────────────────────────────────────────────
class AppRates {
  AppRates._();

  static const double gbpToUsdt = 1.27;
  static const double eurToUsdt = 1.08;
  static const double usdToUsdt = 1.00;
  static const double usdtToUsdt = 1.00;
  static const double tzsToUsdtRate = 1 / 2650.0;
  static const double usdtToTzs = 2650.0;
  static const double spread = 0.015;
  static const double exchangeFeeRate = 0.01;

  static const Map<String, double> cryptoPriceUsd = {
    'BTC': 65000.0,
    'ETH': 3200.0,
    'SOL': 140.0,
    'BNB': 600.0,
    'XRP': 0.60,
    'ADA': 0.45,
    'DOGE': 0.16,
  };

  static const Map<String, double> _toUsdtMid = {
    'GBP': gbpToUsdt,
    'EUR': eurToUsdt,
    'USD': usdToUsdt,
    'USDT': usdtToUsdt,
    'TZS': tzsToUsdtRate,
  };

  static const Map<String, String> currencyFlags = {
    'GBP': '🇬🇧',
    'EUR': '🇪🇺',
    'USD': '🇺🇸',
    'USDT': '🔷',
    'TZS': '🇹🇿',
    'BTC': '₿',
    'ETH': 'Ξ',
    'SOL': '◎',
    'BNB': 'B',
    'XRP': 'X',
    'ADA': 'A',
    'DOGE': 'D',
  };

  static const Map<String, String> currencySymbols = {
    'GBP': '£',
    'EUR': '€',
    'USD': r'$',
    'USDT': '₮',
    'TZS': 'TZS',
    'BTC': '₿',
    'ETH': 'Ξ',
    'SOL': 'SOL',
    'BNB': 'BNB',
    'XRP': 'XRP',
    'ADA': 'ADA',
    'DOGE': 'DOGE',
  };

  static const Map<String, String> currencyNames = {
    'GBP': 'British Pound',
    'EUR': 'Euro',
    'USD': 'US Dollar',
    'USDT': 'Tether',
    'TZS': 'Tanzanian Shilling',
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'SOL': 'Solana',
    'BNB': 'BNB',
    'XRP': 'XRP',
    'ADA': 'Cardano',
    'DOGE': 'Dogecoin',
  };

  static bool isCrypto(String c) => cryptoPriceUsd.containsKey(c);
  static bool isFiat(String c) => _toUsdtMid.containsKey(c);

  static double convert(String from, String to, double amount) {
    if (amount <= 0) return 0;
    if (from == to) return amount;
    return _fromUsd(to, _toUsd(from, amount));
  }

  static double _toUsd(String currency, double amount) {
    if (isCrypto(currency)) return amount * cryptoPriceUsd[currency]!;
    if (currency == 'TZS') return amount / usdtToTzs;
    return amount * (_toUsdtMid[currency] ?? 1.0);
  }

  static double _fromUsd(String currency, double usdAmount) {
    if (isCrypto(currency)) return usdAmount / cryptoPriceUsd[currency]!;
    if (currency == 'TZS') return usdAmount * usdtToTzs;
    return usdAmount / (_toUsdtMid[currency] ?? 1.0);
  }

  static double priceInUsd(String currency) => _toUsd(currency, 1.0);
  static double priceInTzs(String currency) => convert(currency, 'TZS', 1.0);

  static double toUsdt(String currency, double amount) {
    final mid = _toUsdtMid[currency] ?? 1.0;
    return amount * mid * (1 - spread);
  }

  static double usdtToTzsAmount(double usdt) => usdt * usdtToTzs;
  static double tzsToUsdt(double tzs) => tzs / usdtToTzs;

  static double toTzs(String currency, double amount) =>
      usdtToTzsAmount(toUsdt(currency, amount));

  static String tickerLabel(String currency) {
    if (currency == 'USDT') return '1 USDT = 2,650 TZS';
    return '1 $currency ≈ ${toTzs(currency, 1.0).toStringAsFixed(0)} TZS';
  }

  static String rateLabel(String currency) {
    final usdt = toUsdt(currency, 1.0).toStringAsFixed(4);
    final tzs = toTzs(currency, 1.0).toStringAsFixed(0);
    return '1 $currency → $usdt USDT → $tzs TZS  (1.5% spread)';
  }
}

// ─── Fees ──────────────────────────────────────────────────────────────────
class AppFees {
  AppFees._();
  static const double transactionFeeRate = 0.01;
}

// ─── Firestore keys ─────────────────────────────────────────────────────────
class FSKeys {
  FSKeys._();

  static const usersCollection = 'users';
  static const transactionsCollection = 'transactions';
  static const notificationsCollection = 'notifications';
  static const exchangesCollection = 'exchanges';

  static const firstName = 'firstName';
  static const lastName = 'lastName';
  static const fullName = 'fullName';
  static const phone = 'phone';
  static const accNumber = 'accNumber';
  static const pin = 'pin';
  static const balanceTzs = 'balance_tzs';
  static const balanceUsdt = 'balance_usdt';
  static const createdAt = 'createdAt';
}

class TxKeys {
  TxKeys._();

  static const senderId = 'senderId';
  static const senderName = 'senderName';
  static const senderAccNumber = 'senderAccNumber';
  static const receiverId = 'receiverId';
  static const receiverName = 'receiverName';
  static const receiverAccNumber = 'receiverAccNumber';
  static const sentCurrency = 'sentCurrency';
  static const sentAmount = 'sentAmount';
  static const usdtAmount = 'usdtAmount';
  static const amountTzs = 'amountTzs';
  static const feeTzs = 'feeTzs';
  static const totalDebitedTzs = 'totalDebitedTzs';
  static const receivedTzs = 'receivedTzs';
  static const createdAt = 'createdAt';
  static const status = 'status';
}

class ExKeys {
  ExKeys._();

  static const userId = 'userId';
  static const direction = 'direction';
  static const fromAmount = 'fromAmount';
  static const fromCurrency = 'fromCurrency';
  static const toAmount = 'toAmount';
  static const toCurrency = 'toCurrency';
  static const feeTzs = 'feeTzs';
  static const rate = 'rate';
  static const createdAt = 'createdAt';
  static const status = 'status';
}

class NotifKeys {
  NotifKeys._();

  static const userId = 'userId';
  static const title = 'title';
  static const body = 'body';
  static const type = 'type';
  static const txId = 'txId';
  static const amount = 'amount';
  static const isRead = 'isRead';
  static const createdAt = 'createdAt';
}

// ─── Validators ─────────────────────────────────────────────────────────────
class Validators {
  Validators._();

  static bool isValidTZPhone(String phone) =>
      RegExp(r'^0[67]\d{8}$').hasMatch(phone);

  static bool isValidPin(String pin) =>
      pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);

  static String generateAccNumber(String phone) =>
      phone.length >= 5 ? phone.substring(phone.length - 5) : phone;

  static String formatNumber(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  static String formatUsdt(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }

  static String formatDecimal(double value, {int dp = 2}) {
    final parts = value.toStringAsFixed(dp).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return dp > 0 ? '$intPart.${parts[1]}' : intPart;
  }
}

class QuickActionLabels {
  QuickActionLabels._();
  static const send = 'Send';
  static const receive = 'Receive';
  static const exchange = 'Exchange';
  static const history = 'History';
}
