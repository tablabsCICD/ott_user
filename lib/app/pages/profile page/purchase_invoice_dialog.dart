import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void _log(String tag, String message) {
  if (!kDebugMode) return;
  debugPrint('$tag $message', wrapWidth: 1024);
}

/// Host + path only: never logs signed query strings or tokens.
String _safeUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return '<invalid url>';
  return '${uri.scheme}://${uri.host}${uri.path}';
}

/// Opens the invoice for [item] as a dialog over Purchase History (no route,
/// no tab change). Details come from the purchase-history item; the Download
/// button fetches the backend invoice PDF from `invoiceUrl`.
Future<void> showPurchaseInvoiceDialog(
  BuildContext context,
  PurchaseHistoryItem item,
) {
  _log('[PURCHASE_HISTORY_INVOICE_DIALOG]',
      'OPEN itemId=${item.id} hasInvoiceUrl=${(item.invoiceUrl ?? '').trim().isNotEmpty}');
  return showDialog<void>(
    context: context,
    builder: (_) => _PurchaseInvoiceDialog(item: item),
  ).whenComplete(() => _log('[PURCHASE_HISTORY_INVOICE_DIALOG]',
      'CLOSE itemId=${item.id}'));
}

class _PurchaseInvoiceDialog extends StatefulWidget {
  const _PurchaseInvoiceDialog({required this.item});

  final PurchaseHistoryItem item;

  @override
  State<_PurchaseInvoiceDialog> createState() => _PurchaseInvoiceDialogState();
}

class _PurchaseInvoiceDialogState extends State<_PurchaseInvoiceDialog> {
  bool _downloading = false;

  /// Downloaded PDF, kept for this dialog so repeat taps don't re-download.
  Uint8List? _pdfBytes;

  PurchaseHistoryItem get item => widget.item;

  String get _fileName {
    final ref = (item.invoiceNumber ?? item.invoiceId ?? '${item.id ?? ''}')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'Filmytell_Invoice_${ref.isEmpty ? 'purchase' : ref}.pdf';
  }

  Future<void> _download() async {
    if (_downloading) return; // no duplicate downloads
    final l10n = AppLocalizations.of(context)!;
    final url = (item.invoiceUrl ?? '').trim();
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasScheme) {
      CustomToast.show(context, l10n.invoiceDownloadFailed, isSuccess: false);
      return;
    }

    // Web: the browser downloads/opens the backend PDF itself.
    if (kIsWeb) {
      final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (mounted && !ok) {
        CustomToast.show(context, l10n.invoiceDownloadFailed, isSuccess: false);
      }
      return;
    }

    setState(() => _downloading = true);
    final stopwatch = Stopwatch()..start();
    try {
      var bytes = _pdfBytes;
      if (bytes == null) {
        _log('[PURCHASE_HISTORY_INVOICE_DOWNLOAD]', 'GET ${_safeUrl(url)}');
        // The app's auth header only for its own API; never for storage
        // hosts (S3 rejects unexpected Authorization headers, and the token
        // must not leak to other hosts).
        final headers = url.startsWith(ApiConstant.baseUrl)
            ? await ApiHelper().headersForDiagnostics()
            : const <String, String>{};
        final response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 30));
        final body = response.bodyBytes;
        final isPdf = body.length > 4 &&
            String.fromCharCodes(body.take(4)) == '%PDF';
        _log('[PURCHASE_HISTORY_INVOICE_DOWNLOAD]',
            'status=${response.statusCode} bytes=${body.length} isPdf=$isPdf '
                'contentType=${response.headers['content-type']} '
                'duration=${stopwatch.elapsedMilliseconds}ms');
        if (response.statusCode != 200 || !isPdf) {
          throw HttpException('Invoice download failed (${response.statusCode})');
        }
        bytes = body;
        _pdfBytes = body;
      }

      // Save a copy in the app's documents folder (no storage permission
      // needed), then hand the original PDF to the system share sheet so the
      // user can save it to Files/Drive or open it.
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      await file.writeAsBytes(bytes, flush: true);
      _log('[PURCHASE_HISTORY_INVOICE_DOWNLOAD]',
          'SAVED $_fileName (${bytes.length} bytes)');
      if (!mounted) return;
      CustomToast.show(context, l10n.invoiceDownloadedSuccess,
          isSuccess: true);
      await SharePlus.instance.share(
        ShareParams(
          subject: l10n.purchaseInvoice,
          files: [
            XFile.fromData(bytes, mimeType: 'application/pdf', name: _fileName),
          ],
          fileNameOverrides: [_fileName],
        ),
      );
    } catch (error, stackTrace) {
      _log('[PURCHASE_HISTORY_INVOICE_DOWNLOAD]',
          'FAILED ${error.runtimeType}: $error after ${stopwatch.elapsedMilliseconds}ms\n'
              '${stackTrace.toString().split('\n').take(4).join('\n')}');
      if (mounted) {
        CustomToast.show(context, l10n.invoiceDownloadFailed,
            isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = item.content?.title ?? item.itemTitle ?? l10n.purchasedContent;
    final type = item.contentType ?? item.content?.type;
    final invoiceRef = item.invoiceNumber ?? item.invoiceId;
    final paid = (item.amount ?? item.content?.price ?? 0).toDouble();
    final hasInvoiceUrl = (item.invoiceUrl ?? '').trim().isNotEmpty;
    String date(DateTime d) {
      try {
        return DateFormat('dd MMM yyyy, hh:mm a', locale).format(d);
      } catch (_) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(d);
      }
    }

    String money(num v) => '₹${v.toStringAsFixed(2)}';

    final rows = <(String, String)>[
      if (invoiceRef != null) (l10n.invoiceNumber, invoiceRef),
      if (item.purchaseDate != null)
        (l10n.invoicePurchaseDate, date(item.purchaseDate!)),
      (l10n.invoiceContentLabel, title),
      if (type != null && type.trim().isNotEmpty)
        (l10n.invoiceContentType, ContentType.localizedLabel(l10n, type)),
      if (item.transactionId != null) (l10n.transactionId, item.transactionId!),
      if ((item.paymentMethod ?? '').trim().isNotEmpty)
        (l10n.paymentMethod, item.paymentMethod!),
    ];
    final amountRows = <(String, String)>[
      if (item.originalAmount != null)
        (l10n.invoiceOriginalAmount, money(item.originalAmount!)),
      if (item.discountAmount != null && item.discountAmount! > 0)
        (
          (item.couponCode ?? '').trim().isNotEmpty
              ? '${l10n.invoiceDiscountLabel} (${l10n.invoiceCouponLabel}: ${item.couponCode})'
              : l10n.invoiceDiscountLabel,
          '-${money(item.discountAmount!)}'
        ),
    ];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: theme.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.purchaseInvoice,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (label, value) in rows)
                      _InvoiceRow(label: label, value: value),
                    const SizedBox(height: 8),
                    const Divider(),
                    for (final (label, value) in amountRows)
                      _InvoiceRow(label: label, value: value),
                    _InvoiceRow(
                      label: l10n.amountPaid,
                      value: money(paid),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: hasInvoiceUrl && !_downloading ? _download : null,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(_downloading
                      ? l10n.downloadingInvoice
                      : (hasInvoiceUrl
                          ? l10n.downloadInvoice
                          : l10n.invoiceNotAvailable)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(label,
                style: TextStyle(
                    color: emphasize ? null : muted,
                    fontWeight: emphasize ? FontWeight.bold : null)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
                fontSize: emphasize ? 16 : 14,
                color: emphasize ? theme.primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
