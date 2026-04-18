import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/services/transaction_service.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ReceiptScreen extends StatelessWidget {
  final TransactionModel transaction;

  ReceiptScreen({super.key, required this.transaction});

  final GlobalKey _receiptKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final tx = transaction;

    return Scaffold(
      backgroundColor: SColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    // ── Success badge ─────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: SColors.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SColors.green.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: SColors.green,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Transaction Successful',
                      style: TextStyle(
                        color: SColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${tx.sentAmount.toStringAsFixed(2)} ${tx.sentCurrency} '
                      'sent to ${tx.receiverName}',
                      style: SText.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Receipt card (wrapped for screenshot) ─────────────
                    RepaintBoundary(
                      key: _receiptKey,
                      child: Container(
                        decoration: SDecor.balanceCard,
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: SColors.navyBorder,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: SColors.gold.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      color: SColors.gold,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Receipt',
                                        style: TextStyle(
                                          color: SColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(tx.createdAt),
                                        style: SText.tiny,
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: SColors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: SColors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Receipt rows ──────────────────────────────
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _receiptRow(
                                    'Transaction ID',
                                    '#${tx.id.substring(0, 10).toUpperCase()}',
                                  ),
                                  _receiptRow(
                                    'From',
                                    '${tx.senderName} (${tx.senderAccNumber})',
                                  ),
                                  _receiptRow(
                                    'To',
                                    '${tx.receiverName} (${tx.receiverAccNumber})',
                                  ),

                                  const SizedBox(height: 10),
                                  _sectionDivider('CONVERSION'),

                                  _receiptRow(
                                    'Sent',
                                    '${tx.sentAmount.toStringAsFixed(2)} '
                                        '${tx.sentCurrency}',
                                  ),
                                  _receiptRow(
                                    'USDT (after 1.5% spread)',
                                    '${Validators.formatUsdt(tx.usdtAmount)} USDT',
                                    valueColor: SColors.gold,
                                  ),
                                  _receiptRow(
                                    'TZS gross (× 2,650)',
                                    'TZS ${Validators.formatNumber(tx.amountTzs)}',
                                  ),

                                  const SizedBox(height: 10),
                                  _sectionDivider('CHARGES'),

                                  _receiptRow(
                                    'Transaction fee (1%)',
                                    '− TZS ${Validators.formatNumber(tx.feeTzs)}',
                                    valueColor: SColors.red,
                                  ),

                                  const SizedBox(height: 10),
                                  _sectionDivider('SUMMARY'),

                                  _receiptRow(
                                    'Total cost to sender',
                                    'TZS ${Validators.formatNumber(tx.totalDebitedTzs)}',
                                    bold: true,
                                  ),
                                  _receiptRow(
                                    'Recipient received',
                                    'TZS ${Validators.formatNumber(tx.receivedTzs)}',
                                    valueColor: SColors.green,
                                    bold: true,
                                  ),
                                ],
                              ),
                            ),

                            const _TearLine(),

                            // Footer
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    color: SColors.gold,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Powered by Sendra · Fedha zako, Uhuru wako',
                                      style: SText.tiny,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _downloadReceipt(context),
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
                            'Download',
                            style: TextStyle(
                              color: SColors.textSub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _shareReceipt(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: SColors.gold.withOpacity(0.5),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Share',
                            style: TextStyle(
                              color: SColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                      style: SButton.primary,
                      child: const Text(
                        'Back to Home',
                        style: SButton.primaryLabel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Download receipt as image ─────────────────────────────────────────────
  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/receipt_${transaction.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Receipt saved to documents',
              style: TextStyle(color: SColors.navy),
            ),
            backgroundColor: SColors.gold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save receipt: $e'),
            backgroundColor: SColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Share receipt as image ────────────────────────────────────────────────
  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/receipt_${transaction.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Sendra Transaction Receipt · '
            '${transaction.sentAmount.toStringAsFixed(2)} '
            '${transaction.sentCurrency} → '
            'TZS ${Validators.formatNumber(transaction.receivedTzs)}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share receipt: $e'),
            backgroundColor: SColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionDivider(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: SColors.navyLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: SColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: SColors.navyLight)),
        ],
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value, {
    Color valueColor = SColors.textPrimary,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: SText.caption)),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$min';
  }
}

// ─── Tear line ─────────────────────────────────────────────────────────────
class _TearLine extends StatelessWidget {
  const _TearLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        30,
        (i) => Expanded(
          child: Container(
            height: 1,
            color: i.isEven ? SColors.navyBorder : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
