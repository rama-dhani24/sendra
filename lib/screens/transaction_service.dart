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

// ─── Single unified transaction model ────────────────────────────────────────
// Used by: sendMoney() return, ReceiptScreen, HistoryPage, _TxCard
class TransactionModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAccNumber;
  final String receiverId;
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
  final String status;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAccNumber,
    required this.receiverId,
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
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data[TxKeys.createdAt] as Timestamp?;
    return TransactionModel(
      id: doc.id,
      senderId: data[TxKeys.senderId] as String? ?? '',
      senderName: data[TxKeys.senderName] as String? ?? '',
      senderAccNumber: data[TxKeys.senderAccNumber] as String? ?? '',
      receiverId: data[TxKeys.receiverId] as String? ?? '',
      receiverName: data[TxKeys.receiverName] as String? ?? '',
      receiverAccNumber: data[TxKeys.receiverAccNumber] as String? ?? '',
      sentCurrency: data[TxKeys.sentCurrency] as String? ?? 'TZS',
      sentAmount: (data[TxKeys.sentAmount] as num?)?.toDouble() ?? 0,
      usdtAmount: (data[TxKeys.usdtAmount] as num?)?.toDouble() ?? 0,
      amountTzs: (data[TxKeys.amountTzs] as num?)?.toDouble() ?? 0,
      feeTzs: (data[TxKeys.feeTzs] as num?)?.toDouble() ?? 0,
      totalDebitedTzs: (data[TxKeys.totalDebitedTzs] as num?)?.toDouble() ?? 0,
      receivedTzs: (data[TxKeys.receivedTzs] as num?)?.toDouble() ?? 0,
      usdtToTzsRate:
          (data['usdtToTzsRate'] as num?)?.toDouble() ?? AppRates.usdtToTzs,
      status: data[TxKeys.status] as String? ?? 'completed',
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}

// ─── Transaction service ──────────────────────────────────────────────────────
class TransactionService {
  static final _db = FirebaseFirestore.instance;

  static Future<UserLookup?> findUserByAccNumber(String accNumber) async {
    final snap = await _db
        .collection(FSKeys.usersCollection)
        .where(FSKeys.accNumber, isEqualTo: accNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserLookup.fromDoc(snap.docs.first);
  }

  static Future<TransactionModel> sendMoney({
    required UserLookup sender,
    required UserLookup receiver,
    required String currency,
    required double sentAmount,
  }) async {
    if (sentAmount <= 0) throw 'Amount must be greater than 0.';
    if (sender.docId == receiver.docId) throw 'Cannot send money to yourself.';

    final rates = ExchangeRateService.instance.latest;
    final usdtToTzs = rates?.usdtToTzs ?? AppRates.usdtToTzs;
    final spread = rates?.spread ?? AppRates.spread;
    final feeRate = rates?.feeRate ?? AppRates.exchangeFeeRate;

    double usdtAmount;
    double amountTzs;

    if (currency == 'TZS') {
      amountTzs = sentAmount;
      usdtAmount = sentAmount / usdtToTzs;
    } else if (currency == 'USDT') {
      usdtAmount = sentAmount * (1 - spread);
      amountTzs = usdtAmount * usdtToTzs;
    } else {
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
          default:
            fiatRate = AppRates.usdToUsdt;
        }
      }
      usdtAmount = sentAmount * fiatRate * (1 - spread);
      amountTzs = usdtAmount * usdtToTzs;
    }

    final feeTzs = double.parse((amountTzs * feeRate).toStringAsFixed(2));
    final totalDebit = amountTzs + feeTzs;
    final receivedTzs = amountTzs;
    final now = DateTime.now();

    final senderRef = _db.collection(FSKeys.usersCollection).doc(sender.docId);
    final receiverRef = _db
        .collection(FSKeys.usersCollection)
        .doc(receiver.docId);
    final txRef = _db.collection(FSKeys.transactionsCollection).doc();

    await _db.runTransaction((txn) async {
      final sSnap = await txn.get(senderRef);
      final rSnap = await txn.get(receiverRef);

      if (!sSnap.exists) throw 'Sender account not found.';
      if (!rSnap.exists) throw 'Receiver account not found.';

      final senderBal = (sSnap.data()![FSKeys.balanceTzs] as num).toDouble();
      final receiverBal = (rSnap.data()![FSKeys.balanceTzs] as num).toDouble();

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

    await _writeNotifications(
      txId: txRef.id,
      sender: sender,
      receiver: receiver,
      amountTzs: amountTzs,
      feeTzs: feeTzs,
      totalDebit: totalDebit,
      receivedTzs: receivedTzs,
    );

    return TransactionModel(
      id: txRef.id,
      senderId: sender.docId,
      senderName: sender.fullName,
      senderAccNumber: sender.accNumber,
      receiverId: receiver.docId,
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
      status: 'completed',
      createdAt: now,
    );
  }

  static Future<void> _writeNotifications({
    required String txId,
    required UserLookup sender,
    required UserLookup receiver,
    required double amountTzs,
    required double feeTzs,
    required double totalDebit,
    required double receivedTzs,
  }) async {
    final batch = _db.batch();

    batch.set(_db.collection(FSKeys.notificationsCollection).doc(), {
      NotifKeys.userId: sender.docId,
      NotifKeys.title: 'Money Sent',
      NotifKeys.body:
          'You sent TZS ${Validators.formatNumber(amountTzs)} '
          'to ${receiver.fullName}. Fee: TZS ${Validators.formatNumber(feeTzs)}.',
      NotifKeys.type: 'debit',
      NotifKeys.txId: txId,
      NotifKeys.amount: totalDebit,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });

    batch.set(_db.collection(FSKeys.notificationsCollection).doc(), {
      NotifKeys.userId: receiver.docId,
      NotifKeys.title: 'Money Received',
      NotifKeys.body:
          'You received TZS ${Validators.formatNumber(receivedTzs)} from ${sender.fullName}.',
      NotifKeys.type: 'credit',
      NotifKeys.txId: txId,
      NotifKeys.amount: receivedTzs,
      NotifKeys.isRead: false,
      NotifKeys.createdAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
