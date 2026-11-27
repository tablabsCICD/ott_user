import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog showing a complete snapshot of a confirmed purchase including
/// content title, original price, applied coupon, discount amount,
/// final payable amount, payment status, order/transaction reference,
/// and optional invoice link.
class PurchaseConfirmationDialog extends StatelessWidget {
  final String contentTitle;
  final double originalPrice;
  final double finalAmountPaid;
  final double? discountAmount;
  final String? couponCode;
  final String currency;
  final String paymentMethod;
  final String? orderReference;
  final DateTime? purchaseDate;
  final String? invoiceUrl;
  final VoidCallback? onDone;

  const PurchaseConfirmationDialog({
    super.key,
    required this.contentTitle,
    required this.originalPrice,
    required this.finalAmountPaid,
    this.discountAmount,
    this.couponCode,
    this.currency = 'INR',
    this.paymentMethod = 'Wallet',
    this.orderReference,
    this.purchaseDate,
    this.invoiceUrl,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required String contentTitle,
    required double originalPrice,
    required double finalAmountPaid,
    double? discountAmount,
    String? couponCode,
    String currency = 'INR',
    String paymentMethod = 'Wallet',
    String? orderReference,
    DateTime? purchaseDate,
    String? invoiceUrl,
    VoidCallback? onDone,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PurchaseConfirmationDialog(
        contentTitle: contentTitle,
        originalPrice: originalPrice,
        finalAmountPaid: finalAmountPaid,
        discountAmount: discountAmount,
        couponCode: couponCode,
        currency: currency,
        paymentMethod: paymentMethod,
        orderReference: orderReference,
        purchaseDate: purchaseDate,
        invoiceUrl: invoiceUrl,
        onDone: onDone,
      ),
    );
  }

  String _formatCurrency(double amount) {
    final symbol = currency.toUpperCase() == 'INR' || currency == '₹' ? '₹' : '$currency ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = purchaseDate ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    final hasCoupon = couponCode != null && couponCode!.trim().isNotEmpty;
    final discount = discountAmount ?? (hasCoupon ? (originalPrice - finalAmountPaid).clamp(0.0, double.infinity) : 0.0);

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveWidget.isMobile(context) ? double.infinity : 480,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Header Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  contentTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Itemized snapshot
              _buildDetailRow(
                context,
                label: 'Original Price',
                value: _formatCurrency(originalPrice),
              ),
              if (hasCoupon) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  label: 'Coupon Applied',
                  value: couponCode!.toUpperCase(),
                  valueColor: Colors.green.shade700,
                  isBold: true,
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    context,
                    label: 'Discount',
                    value: '-${_formatCurrency(discount)}',
                    valueColor: Colors.green.shade700,
                    isBold: true,
                  ),
                ],
              ],
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                label: 'Amount Paid',
                value: _formatCurrency(finalAmountPaid),
                isBold: true,
                fontSize: 16,
                valueColor: theme.primaryColor,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                label: 'Payment Method',
                value: paymentMethod,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                label: 'Payment Status',
                value: 'Successful',
                valueColor: Colors.green,
                isBold: true,
              ),
              if (orderReference != null && orderReference!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  context,
                  label: 'Order ID',
                  value: orderReference!,
                  isSelectable: true,
                ),
              ],
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                label: 'Date & Time',
                value: formattedDate,
              ),

              if (invoiceUrl != null && invoiceUrl!.isNotEmpty) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(invoiceUrl!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('View Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDone?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    double fontSize = 14,
    bool isSelectable = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: theme.canvasColor.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: isSelectable
              ? SelectableText(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? theme.canvasColor,
                  ),
                )
              : Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: valueColor ?? theme.canvasColor,
                  ),
                ),
        ),
      ],
    );
  }
}
