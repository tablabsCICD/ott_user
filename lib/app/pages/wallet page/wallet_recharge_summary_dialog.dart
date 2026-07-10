import 'package:flutter/material.dart';

class WalletRechargeSummaryDialog extends StatelessWidget {
  const WalletRechargeSummaryDialog({
    super.key,
    required this.requestedAmount,
    required this.creditedAmount,
    this.deductionAmount,
    this.deductionPercentage,
    this.deductionLabel,
    this.paymentGateway,
    this.settlementType,
  });

  final double requestedAmount;
  final double creditedAmount;
  final double? deductionAmount;
  final double? deductionPercentage;
  final String? deductionLabel;
  final String? paymentGateway;
  final String? settlementType;

  bool get _hasDeduction => (deductionAmount ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Wallet Recharge Successful'),
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primaryColor.withOpacity(0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              label: 'Requested Amount',
              value: _formatCurrency(requestedAmount),
            ),
            if (_hasDeduction)
              _SummaryRow(
                label: _deductionTitle,
                value: _formatCurrency(deductionAmount!),
              ),
            _SummaryRow(
              label: _hasDeduction ? 'Wallet Credited' : 'Credited Amount',
              value: _formatCurrency(creditedAmount),
              valueColor: Colors.green,
              isStrong: true,
            ),
            if ((settlementType ?? '').trim().isNotEmpty)
              _SummaryRow(
                label: 'Settlement',
                value: _formatLabel(settlementType!),
              ),
            if ((paymentGateway ?? '').trim().isNotEmpty)
              _SummaryRow(
                label: 'Gateway',
                value: _formatLabel(paymentGateway!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  String get _deductionTitle {
    final percentage = deductionPercentage;
    final label = deductionLabel ?? 'Apple Deduction';
    if (percentage == null || percentage <= 0) return label;
    return '$label (${percentage.toStringAsFixed(0)}%)';
  }

  static String _formatCurrency(double value) {
    return '\u20B9${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }

  static String _formatLabel(String value) {
    final normalized = value.trim().replaceAll('_', ' ').toLowerCase();
    if (normalized.isEmpty) return value;
    return normalized
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isStrong = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: theme.canvasColor.withOpacity(0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? theme.canvasColor,
              fontWeight: isStrong ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
