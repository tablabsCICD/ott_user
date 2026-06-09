import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/data/models/user.dart';

enum InvoiceShareTarget { whatsapp, email, general }

class PurchaseInvoiceData {
  const PurchaseInvoiceData({
    required this.user,
    required this.contentTitle,
    required this.contentType,
    required this.amount,
    required this.purchaseDate,
    this.itemTitle,
    this.itemSubtitle,
    this.rentalDuration,
    this.paymentMethod = 'Wallet',
    this.quantity = 1,
    this.invoiceNumber,
  });

  final User user;
  final String contentTitle;
  final String contentType;
  final double amount;
  final DateTime purchaseDate;
  final String? itemTitle;
  final String? itemSubtitle;
  final String? rentalDuration;
  final String paymentMethod;
  final int quantity;
  final String? invoiceNumber;
}

class GeneratedInvoice {
  const GeneratedInvoice({
    required this.bytes,
    required this.fileName,
    required this.invoiceNumber,
    required this.subject,
    required this.message,
  });

  final Uint8List bytes;
  final String fileName;
  final String invoiceNumber;
  final String subject;
  final String message;
}

class InvoiceService {
  InvoiceService._();

  static final InvoiceService instance = InvoiceService._();

  Future<GeneratedInvoice> generatePurchaseInvoice(
    PurchaseInvoiceData data,
  ) async {
    final invoiceNumber = data.invoiceNumber ?? _buildInvoiceNumber(data);
    final pdf = pw.Document();
    final logoBytes = await _loadLogoBytes();
    final logo = logoBytes == null ? null : pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildHeader(logo, invoiceNumber, data.purchaseDate),
          pw.SizedBox(height: 16),
          _buildCustomerSection(data),
          pw.SizedBox(height: 16),
          _buildPurchaseSection(data),
          pw.SizedBox(height: 16),
          _buildSummarySection(data),
          pw.SizedBox(height: 24),
          pw.Text(
            'Thank you for your purchase on Filmytell.',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );

    final sanitizedTitle = _sanitizeFileName(data.contentTitle);
    final pdfBytes = await pdf.save();
    final fileName = 'invoice_${sanitizedTitle}_$invoiceNumber.pdf';

    final subject = 'Filmytell Invoice $invoiceNumber';
    final message = _buildShareMessage(data, invoiceNumber);

    return GeneratedInvoice(
      bytes: pdfBytes,
      fileName: fileName,
      invoiceNumber: invoiceNumber,
      subject: subject,
      message: message,
    );
  }

  Future<void> shareInvoice(
    GeneratedInvoice invoice, {
    required InvoiceShareTarget target,
  }) {
    final channelHint = switch (target) {
      InvoiceShareTarget.whatsapp => 'Select WhatsApp to share this invoice.',
      InvoiceShareTarget.email => 'Select your email app to send this invoice.',
      InvoiceShareTarget.general => 'Share invoice',
    };

    return SharePlus.instance.share(
      ShareParams(
        subject: invoice.subject,
        text: '${invoice.message}\n\n$channelHint',
        files: [
          XFile.fromData(
            invoice.bytes,
            mimeType: 'application/pdf',
            name: invoice.fileName,
          ),
        ],
        fileNameOverrides: [invoice.fileName],
      ),
    );
  }

  Future<void> showShareOptions(
    BuildContext context,
    GeneratedInvoice invoice,
  ) async {
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invoice ready',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Invoice ${invoice.invoiceNumber} has been generated. '
                  'Choose where to share it.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                _ShareActionTile(
                  icon: Icons.chat,
                  title: 'Send on WhatsApp',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await shareInvoice(
                      invoice,
                      target: InvoiceShareTarget.whatsapp,
                    );
                  },
                ),
                _ShareActionTile(
                  icon: Icons.email_outlined,
                  title: 'Send by Email',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await shareInvoice(
                      invoice,
                      target: InvoiceShareTarget.email,
                    );
                  },
                ),
                _ShareActionTile(
                  icon: Icons.share_outlined,
                  title: 'More sharing options',
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await shareInvoice(
                      invoice,
                      target: InvoiceShareTarget.general,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    String invoiceNumber,
    DateTime purchaseDate,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            if (logo != null)
              pw.Container(
                width: 54,
                height: 54,
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColors.red50,
                ),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Image(logo),
              ),
            pw.SizedBox(width: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Filmytell',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
                pw.Text(
                  'Purchase Invoice',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Invoice No.',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              invoiceNumber,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(purchaseDate),
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerSection(PurchaseInvoiceData data) {
    final user = data.user;
    final customerName =
        '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim().isEmpty
            ? 'Filmytell User'
            : '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();

    return _buildCard(
      title: 'Customer Details',
      rows: [
        _InvoiceRowData('Name', customerName),
        _InvoiceRowData('Email', _valueOrFallback(user.emailId)),
        _InvoiceRowData('Mobile', _valueOrFallback(user.mobileNumber)),
        _InvoiceRowData('User ID', user.id?.toString() ?? 'N/A'),
      ],
    );
  }

  pw.Widget _buildPurchaseSection(PurchaseInvoiceData data) {
    return _buildCard(
      title: 'Purchase Details',
      rows: [
        _InvoiceRowData('Content', data.contentTitle),
        _InvoiceRowData('Content Type', data.contentType),
        if ((data.itemTitle ?? '').trim().isNotEmpty)
          _InvoiceRowData('Purchased Item', data.itemTitle!.trim()),
        if ((data.itemSubtitle ?? '').trim().isNotEmpty)
          _InvoiceRowData('Details', data.itemSubtitle!.trim()),
        if ((data.rentalDuration ?? '').trim().isNotEmpty)
          _InvoiceRowData('Rental Duration', data.rentalDuration!.trim()),
        _InvoiceRowData('Payment Method', data.paymentMethod),
      ],
    );
  }

  pw.Widget _buildSummarySection(PurchaseInvoiceData data) {
    final total = data.amount * data.quantity;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Amount Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          _summaryRow('Unit Price', _formatCurrency(data.amount)),
          _summaryRow('Quantity', '${data.quantity}'),
          _summaryRow('Total Paid', _formatCurrency(total), emphasize: true),
        ],
      ),
    );
  }

  pw.Widget _buildCard({
    required String title,
    required List<_InvoiceRowData> rows,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...rows.map(_invoiceRow),
        ],
      ),
    );
  }

  pw.Widget _invoiceRow(_InvoiceRowData row) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              row.label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              row.value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, String value, {bool emphasize = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: emphasize ? 14 : 12,
              fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: emphasize ? PdfColors.red700 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadLogoBytes() async {
    try {
      final data = await rootBundle.load(ImageConstant.logo);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  String _buildInvoiceNumber(PurchaseInvoiceData data) {
    final timestamp = DateFormat('yyyyMMddHHmmss').format(data.purchaseDate);
    final userId = data.user.id?.toString() ?? '0';
    return 'FT-$userId-$timestamp';
  }

  String _buildShareMessage(PurchaseInvoiceData data, String invoiceNumber) {
    return 'Filmytell invoice $invoiceNumber for ${data.contentTitle}. '
        'Amount paid: ${_formatCurrency(data.amount * data.quantity)}.';
  }

  String _formatCurrency(double amount) {
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    return sanitized.isEmpty ? 'content' : sanitized;
  }

  String _valueOrFallback(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'N/A' : trimmed;
  }
}

class _InvoiceRowData {
  const _InvoiceRowData(this.label, this.value);

  final String label;
  final String value;
}

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
