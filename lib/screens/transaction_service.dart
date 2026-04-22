import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/services/exchange_rate_service.dart';

// ─── User lookup model ───────────────────────────────────────────────────────
class UserLookup {
  final String docId;
  final String fullName;
  final String accNumber;
  final String phone;
  final double balanceTzs;

  const UserLookup({
    required this.docId,
    required this.fullName,
    required this.accNumber,
    required this.phone,
    required this.balanceTzs,
  });

  factory UserLookup.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserLookup(
      docId: doc.id,
      fullName: data[FSKeys.fullName] as String? ?? '',
      accNumber: data[FSKeys.accNumber] as String? ?? '',
      phone: data[FSKeys.phone] as String? ?? '',
      balanceTzs: (data[FSKeys.balanceTzs] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Transaction result model ────────────────────────────────────────────────
class TransactionResult {
  final String txId;
  final String senderName;
  final String receiverName;
  final String receiverAccNumber;
  final String sentCurrency;
  final double sentAmount;
  final double usdtAmount;
  final double amountTzs;
  final double feeTzs;
  final double totalDebitedTzs;
  final double receivedTzs;
  final double usdtToTzsRate;
  final DateTime createdAt;

  const TransactionResult({
    required this.txId,
    required this.senderName,
    required this.receiverName,
    required this.receiverAccNumber,
    required this.sentCurrency,
    required this.sentAmount,
    required this.usdtAmount,
    required this.amountTzs,
    required this.feeTzs,
    required this.totalDebitedTzs,
    required this.receivedTzs,
    required this.usdtToTzsRate,
    required this.createdAt,
  });
}

// ─── Transaction service ─────────────────────────────────────────────────────
class TransactionService {
  static final _db = FirebaseFirestore.instance;

  // ── Find user by 5-digit Sendra ID ──────────────────────────────────────
  static Future<UserLookup?> findUserByAccNumber(String accNumber) async {
    final snap = await _db
        .collection(FSKeys.usersCollection)
        .where(FSKeys.accNumber, isEqualTo: accNumber)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return UserLookup.fromDoc(snap.docs.first);
  }

  // ── Core send money flow ─────────────────────────────────────────────────
  static Future<TransactionResult> sendMoney({
    required UserLookup sender,
    required UserLookup receiver,
    required String currency,
    required double sentAmount,
  }) async {
    if (sentAmount <= 0) throw 'Amount must be greater than 0.';
    if (sender.docId == receiver.docId) throw 'Cannot send money to yourself.';

    // Snapshot live rates at execution time
    final rates = ExchangeRateService.instance.latest;
    final usdtToTzs = rates?.usdtToTzs ?? AppRates.usdtToTzs;
    final spread = rates?.spread ?? AppRates.spread;
    final feeRate = rates?.feeRate ?? AppRates.exchangeFeeRate;

    // Conversion: sent currency → USDT → TZS
    double usdtAmount;
    double amountTzs;

    if (currency == 'TZS') {
      amountTzs = sentAmount;
      usdtAmount = sentAmount / usdtToTzs;
    } else if (currency == 'USDT') {
      usdtAmount = sentAmount * (1 - spread);
      amountTzs = usdtAmount * usdtToTzs;
    } else {
      // Fiat: GBP | EUR | USD
      double fiatRate;
      if (rates != null && rates.fiat.containsKey(currency)) {
        fiatRate = rates.fiat[currency]!;
      } else {
        switch (currency) {
          case 'GBP':
            fiatRate = AppRates.gbpToUsdt;
            break;
          case 'EUR':
            fiatRate = AppRates.eurToUsdt;
            break;
          case 'USD':
            fiatRate = AppRates.usdToUsdt;
            break;
          default:
            fiatRate = 1.0;
        }
      }
      usdtAmount = sentAmount * fiatRate * (1 - spread);
      amountTzs = usdtAmount * usdtToTzs;
    }

    // Fee calculation
    final feeTzs = double.parse((amountTzs * feeRate).toStringAsFixed(2));
    final totalDebit = amountTzs + feeTzs;
    final receivedTzs = amountTzs;

    // Firestore atomic transaction
    final senderRef = _db.collection(FSKeys.usersCollection).doc(sender.docId);
    final receiverRef = _db
        .collection(FSKeys.usersCollection)
        .doc(receiver.docId);
    final txRef = _db.collection(FSKeys.transactionsCollection).doc();

    await _db.runTransaction((txn) async {
      final senderSnap = await txn.get(senderRef);
      final receiverSnap = await txn.get(receiverRef);

      if (!senderSnap.exists) throw 'Sender account not found.';
      if (!receiverSnap.exists) throw 'Receiver account not found.';

      final senderBal = (senderSnap.data()![FSKeys.balanceTzs] as num)
          .toDouble();
      final receiverBal = (receiverSnap.data()![FSKeys.balanceTzs] as num)
          .toDouble();

      if (senderBal < totalDebit) {
        throw 'Insufficient balance. You need TZS ${Validators.formatNumber(totalDebit)} '
            '(incl. TZS ${Validators.formatNumber(feeTzs)} fee).';
      }

      txn.update(senderRef, {FSKeys.balanceTzs: senderBal - totalDebit});
      txn.update(receiverRef, {FSKeys.balanceTzs: receiverBal + receivedTzs});

      txn.set(txRef, {
        TxKeys.senderId: sender.docId,
        TxKeys.senderName: sender.fullName,
        TxKeys.senderAccNumber: sender.accNumber,
        TxKeys.receiverId: receiver.docId,
        TxKeys.receiverName: receiver.fullName,
        TxKeys.receiverAccNumber: receiver.accNumber,
        TxKeys.sentCurrency: currency,
        TxKeys.sentAmount: sentAmount,
        TxKeys.usdtAmount: usdtAmount,
        TxKeys.amountTzs: amountTzs,
        TxKeys.feeTzs: feeTzs,
        TxKeys.totalDebitedTzs: totalDebit,
        TxKeys.receivedTzs: receivedTzs,
        'usdtToTzsRate': usdtToTzs,
        'rateSrc': rates != null ? 'live' : 'fallback',
        TxKeys.status: 'completed',
        TxKeys.createdAt: FieldValue.serverTimestamp(),
      });
    });

    // Notifications — outside atomic txn, non-critical
    await _sendNotifications(
      txId: txRef.id,
      sender: sender,
      receiver: receiver,
      amountTzs: amountTzs,
      feeTzs: feeTzs,
      totalDebit: totalDebit,
      receivedTzs: receivedTzs,
    );

    return TransactionResult(
      txId: txRef.id,
      senderName: sender.fullName,
      receiverName: receiver.fullName,
      receiverAccNumber: receiver.accNumber,
      sentCurrency: currency,
      sentAmount: sentAmount,
      usdtAmount: usdtAmount,
      amountTzs: amountTzs,
      feeTzs: feeTzs,
      totalDebitedTzs: totalDebit,
      receivedTzs: receivedTzs,
      usdtToTzsRate: usdtToTzs,
      createdAt: DateTime.now(),
    );
  }

  // ── Notifications ────────────────────────────────────────────────────────
  static Future<void> _sendNotifications({
    required String txId,
    required UserLookup sender,
    required UserLookup receiver,
    required double amountTzs,
    required double feeTzs,
    required double totalDebit,
    required double receivedTzs,
  }) async {
    final batch = _db.batch();

    final senderNotif = _db.collection(FSKeys.notificationsCollection).doc();
    batch.set(senderNotif, {
      NotifKeys.userId: sender.docId,
      NotifKeys.title: 'Money Sent',
      NotifKeys.body:
          'You sent TZS ${Validators.formatNumber(amountTzs)} '
          'to ${receiver.fullName}. '
          'Fee: TZS ${Validators.formatNumber(feeTzs)}.',
      NotifKeys.type: 'debit',
      NotifKeys.txId: txId,
      NotifKeys.amount: totalDebit,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });

    final receiverNotif = _db.collection(FSKeys.notificationsCollection).doc();
    batch.set(receiverNotif, {
      NotifKeys.userId: receiver.docId,
      NotifKeys.title: 'Money Received',
      NotifKeys.body:
          'You received TZS ${Validators.formatNumber(receivedTzs)} '
          'from ${sender.fullName}.',
      NotifKeys.type: 'credit',
      NotifKeys.txId: txId,
      NotifKeys.amount: receivedTzs,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
