import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sendra/core/constants.dart';

// ─── Transaction model ──────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAccNumber;
  final String receiverId;
  final String receiverName;
  final String receiverAccNumber;
  final String sentCurrency; // 'GBP' | 'USD' | 'EUR' | 'USDT'
  final double sentAmount; // raw foreign amount sender typed
  final double usdtAmount; // USDT after spread
  final double amountTzs; // gross TZS (usdtAmount × 2650)
  final double feeTzs; // 1% of gross TZS
  final double totalDebitedTzs; // grossTzs + fee (sender pays)
  final double receivedTzs; // grossTzs − fee (receiver gets)
  final DateTime createdAt;
  final String status;

  const TransactionModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAccNumber,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAccNumber,
    this.sentCurrency = 'TZS',
    this.sentAmount = 0,
    this.usdtAmount = 0,
    required this.amountTzs,
    required this.feeTzs,
    required this.totalDebitedTzs,
    required this.receivedTzs,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    TxKeys.senderId: senderId,
    TxKeys.senderName: senderName,
    TxKeys.senderAccNumber: senderAccNumber,
    TxKeys.receiverId: receiverId,
    TxKeys.receiverName: receiverName,
    TxKeys.receiverAccNumber: receiverAccNumber,
    TxKeys.sentCurrency: sentCurrency,
    TxKeys.sentAmount: sentAmount,
    TxKeys.usdtAmount: usdtAmount,
    TxKeys.amountTzs: amountTzs,
    TxKeys.feeTzs: feeTzs,
    TxKeys.totalDebitedTzs: totalDebitedTzs,
    TxKeys.receivedTzs: receivedTzs,
    TxKeys.createdAt: FieldValue.serverTimestamp(),
    TxKeys.status: status,
  };
}

// ─── User lookup result ─────────────────────────────────────────────────────
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

  factory UserLookup.fromDoc(String docId, Map<String, dynamic> data) {
    return UserLookup(
      docId: docId,
      fullName: data[FSKeys.fullName] as String? ?? '',
      accNumber: data[FSKeys.accNumber] as String? ?? '',
      phone: data[FSKeys.phone] as String? ?? '',
      balanceTzs: (data[FSKeys.balanceTzs] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// ─── Transaction service ────────────────────────────────────────────────────
class TransactionService {
  static final _db = FirebaseFirestore.instance;

  // ── Look up receiver by account number ────────────────────────────────────
  static Future<UserLookup?> findUserByAccNumber(String accNumber) async {
    final snap = await _db
        .collection(FSKeys.usersCollection)
        .where(FSKeys.accNumber, isEqualTo: accNumber.trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return UserLookup.fromDoc(snap.docs.first.id, snap.docs.first.data());
  }

  // ── Execute transaction ───────────────────────────────────────────────────
  // currency   = 'GBP' | 'EUR' | 'USD' | 'USDT'
  // sentAmount = raw foreign amount the sender typed
  // Returns the completed TransactionModel. Throws String on failure.
  static Future<TransactionModel> sendMoney({
    required UserLookup sender,
    required UserLookup receiver,
    required String currency,
    required double sentAmount,
  }) async {
    if (sentAmount <= 0) throw 'Amount must be greater than 0.';
    if (sender.docId == receiver.docId) {
      throw 'You cannot send money to yourself.';
    }

    // Full pipeline: foreign → USDT (after spread) → TZS → fee
    final usdt = AppRates.toUsdt(currency, sentAmount);
    final grossTzs = AppRates.usdtToTzsAmount(usdt);
    final fee = _calcFee(grossTzs);
    final receivedTzs = grossTzs - fee;
    final totalDebited = grossTzs + fee;

    if (sender.balanceTzs < totalDebited) {
      throw 'Insufficient balance. You need '
          'TZS ${Validators.formatNumber(totalDebited)} '
          '(including TZS ${Validators.formatNumber(fee)} fee) but have '
          'TZS ${Validators.formatNumber(sender.balanceTzs)}.';
    }

    final txRef = _db.collection(FSKeys.transactionsCollection).doc();

    final model = TransactionModel(
      id: txRef.id,
      senderId: sender.docId,
      senderName: sender.fullName,
      senderAccNumber: sender.accNumber,
      receiverId: receiver.docId,
      receiverName: receiver.fullName,
      receiverAccNumber: receiver.accNumber,
      sentCurrency: currency,
      sentAmount: sentAmount,
      usdtAmount: usdt,
      amountTzs: grossTzs,
      feeTzs: fee,
      totalDebitedTzs: totalDebited,
      receivedTzs: receivedTzs,
      createdAt: DateTime.now(),
      status: 'completed',
    );

    await _db.runTransaction((txn) async {
      final senderRef = _db
          .collection(FSKeys.usersCollection)
          .doc(sender.docId);
      final receiverRef = _db
          .collection(FSKeys.usersCollection)
          .doc(receiver.docId);

      final senderSnap = await txn.get(senderRef);
      final receiverSnap = await txn.get(receiverRef);

      final senderBal = (senderSnap.data()![FSKeys.balanceTzs] as num)
          .toDouble();
      final receiverBal = (receiverSnap.data()![FSKeys.balanceTzs] as num)
          .toDouble();

      if (senderBal < totalDebited) throw 'Insufficient balance.';

      // Debit sender
      txn.update(senderRef, {FSKeys.balanceTzs: senderBal - totalDebited});

      // Credit receiver
      txn.update(receiverRef, {FSKeys.balanceTzs: receiverBal + receivedTzs});

      // Write transaction doc
      txn.set(txRef, model.toMap());

      // Notification — sender (debit)
      txn.set(
        _db.collection(FSKeys.notificationsCollection).doc(),
        _buildNotif(
          userId: sender.docId,
          title: 'Money Sent',
          body:
              'You sent ${sentAmount.toStringAsFixed(2)} $currency '
              'to ${receiver.fullName}. '
              'Deducted: TZS ${Validators.formatNumber(totalDebited)}.',
          type: 'debit',
          txId: txRef.id,
          amount: grossTzs,
        ),
      );

      // Notification — receiver (credit)
      txn.set(
        _db.collection(FSKeys.notificationsCollection).doc(),
        _buildNotif(
          userId: receiver.docId,
          title: 'Money Received',
          body:
              'You received TZS ${Validators.formatNumber(receivedTzs)} '
              'from ${sender.fullName}.',
          type: 'credit',
          txId: txRef.id,
          amount: receivedTzs,
        ),
      );
    });

    return model;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static double _calcFee(double grossTzs) =>
      double.parse((grossTzs * AppFees.transactionFeeRate).toStringAsFixed(2));

  static Map<String, dynamic> _buildNotif({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String txId,
    required double amount,
  }) => {
    NotifKeys.userId: userId,
    NotifKeys.title: title,
    NotifKeys.body: body,
    NotifKeys.type: type,
    NotifKeys.txId: txId,
    NotifKeys.amount: amount,
    NotifKeys.isRead: false,
    NotifKeys.createdAt: FieldValue.serverTimestamp(),
  };
}
