import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sendra/core/theme.dart';
import 'package:sendra/core/constants.dart';
import 'package:sendra/screens/transaction_service.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sendra/core/html_stub.dart'
    if (dart.library.html) 'dart:html'
    as html;

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
                      '${tx.sentAmount.toStringAsFixed(2)} ${tx.sentCurrency} sent to ${tx.receiverName}',
                      style: SText.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    RepaintBoundary(
                      key: _receiptKey,
                      child: Container(
                        decoration: SDecor.balanceCard,
                        child: Column(
                          children: [
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
                                  _receiptRow('You sent', _fmtSent(tx)),
                                  if (tx.sentCurrency != 'TZS')
                                    _receiptRow(
                                      'USDT equivalent',
                                      '${Validators.formatUsdt(tx.usdtAmount)} USDT',
                                      valueColor: SColors.gold,
                                    ),
                                  _receiptRow(
                                    'Rate used',
                                    '1 USDT = TZS ${Validators.formatNumber(tx.usdtToTzsRate)}',
                                  ),
                                  _receiptRow(
                                    'TZS amount',
                                    'TZS ${Validators.formatNumber(tx.amountTzs)}',
                                  ),
                                  const SizedBox(height: 10),
                                  _sectionDivider('CHARGES'),
                                  _receiptRow(
                                    'Transaction fee (1%)',
                                    '- TZS ${Validators.formatNumber(tx.feeTzs)}',
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

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _downloadReceipt(context),
                          child: const Text('Download'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _shareReceipt(context),
                          child: const Text('Share'),
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

  String _fmtSent(TransactionModel tx) {
    final dp = tx.sentCurrency == 'TZS' ? 0 : 4;
    return '${tx.sentAmount.toStringAsFixed(dp)} ${tx.sentCurrency}';
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        // ✅ Use .download property directly — avoids setAttribute error on stub
        final anchor = html.AnchorElement(href: url)
          ..download = 'receipt_${transaction.id}.png'
          ..click();
        html.Url.revokeObjectUrl(url);
        // ignore: unused_local_variable
        final _ = anchor;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/receipt_${transaction.id}.png');
        await file.writeAsBytes(bytes);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Receipt downloaded!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save receipt: $e')));
      }
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        // ✅ Use .download property directly — avoids setAttribute error on stub
        final anchor = html.AnchorElement(href: url)
          ..download = 'receipt_${transaction.id}.png'
          ..click();
        html.Url.revokeObjectUrl(url);
        // ignore: unused_local_variable
        final _ = anchor;
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/receipt_${transaction.id}.png');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Sendra Receipt · '
              '${transaction.sentAmount.toStringAsFixed(2)} '
              '${transaction.sentCurrency} -> '
              'TZS ${Validators.formatNumber(transaction.receivedTzs)}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not share receipt: $e')));
      }
    }
  }

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
        children: [
          Expanded(child: Text(label, style: SText.caption)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
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
    final m = dt.minute.toString().padLeft(2, '0');

    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }
}

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
