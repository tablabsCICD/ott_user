import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/services/coupon_service.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/data/models/coupon/coupon_models.dart';
import 'package:provider/provider.dart';

class CouponSectionWidget extends StatefulWidget {
  const CouponSectionWidget({
    super.key,
    required this.purchaseKind,
    required this.targetId,
    required this.originalPrice,
    this.onCouponChanged,
    this.onCouponApplied,
    this.onCouponRemoved,
    this.appliedCoupon,
    this.initialCoupon,
    this.currencySymbol = '₹',
  });

  final String purchaseKind;
  final int targetId;
  final double originalPrice;
  final ValueChanged<CouponValidationData?>? onCouponChanged;
  final ValueChanged<CouponValidationData>? onCouponApplied;
  final VoidCallback? onCouponRemoved;
  final CouponValidationData? appliedCoupon;
  final CouponValidationData? initialCoupon;
  final String currencySymbol;

  @override
  State<CouponSectionWidget> createState() => _CouponSectionWidgetState();
}

class _CouponSectionWidgetState extends State<CouponSectionWidget> {
  final TextEditingController _controller = TextEditingController();
  final CouponService _couponService = CouponService();
  final FocusNode _focusNode = FocusNode();

  bool _isValidating = false;
  String? _errorMessage;
  CouponValidationData? _appliedCoupon;

  @override
  void initState() {
    super.initState();
    _appliedCoupon = widget.appliedCoupon ?? widget.initialCoupon;
    if (_appliedCoupon != null) {
      _controller.text = _appliedCoupon!.couponCode;
    }
  }

  @override
  void didUpdateWidget(covariant CouponSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextCoupon = widget.appliedCoupon ?? widget.initialCoupon;
    final oldCoupon = oldWidget.appliedCoupon ?? oldWidget.initialCoupon;
    if (nextCoupon != oldCoupon) {
      setState(() {
        _appliedCoupon = nextCoupon;
        if (_appliedCoupon != null) {
          _controller.text = _appliedCoupon!.couponCode;
        } else {
          _controller.clear();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty || _isValidating) return;

    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (user?.id == null) {
      setState(() {
        _errorMessage = 'Please sign in to apply coupons.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final response = await _couponService.validateCoupon(
        couponCode: code,
        userId: user!.id!,
        purchaseKind: widget.purchaseKind,
        targetId: widget.targetId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _appliedCoupon = response.data;
          _errorMessage = null;
          _isValidating = false;
        });
        widget.onCouponApplied?.call(response.data!);
        widget.onCouponChanged?.call(_appliedCoupon);
      } else {
        setState(() {
          _errorMessage = response.userFriendlyMessage;
          _isValidating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = resolveCouponErrorMessage(fallbackMessage: e.toString());
        _isValidating = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _errorMessage = null;
      _controller.clear();
    });
    widget.onCouponRemoved?.call();
    widget.onCouponChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _appliedCoupon != null
              ? Colors.green.shade600.withOpacity(0.6)
              : theme.dividerColor.withOpacity(0.12),
          width: _appliedCoupon != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Have a coupon code?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.canvasColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_appliedCoupon == null) ...[
            // Input + Apply row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                      _UpperCaseTextFormatter(),
                    ],
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      } else {
                        setState(() {});
                      }
                    },
                    onSubmitted: (_) => _applyCoupon(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                      color: theme.canvasColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: theme.canvasColor.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? Colors.redAccent
                              : theme.dividerColor.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? Colors.redAccent
                              : theme.dividerColor.withOpacity(0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _errorMessage != null
                              ? Colors.redAccent
                              : theme.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _controller.text.trim().isEmpty || _isValidating
                        ? null
                        : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          theme.primaryColor.withOpacity(0.4),
                      disabledForegroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: _isValidating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Apply',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ] else ...[
            // Applied coupon presentation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade900.withOpacity(isDark ? 0.25 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.shade600.withOpacity(0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_appliedCoupon!.couponCode} ✓ Applied',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You save ${widget.currencySymbol}${_appliedCoupon!.discountAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _removeCoupon,
                    icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                    label: const Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Itemized price breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  _PriceRow(
                    label: 'Original Price',
                    amount:
                        '${widget.currencySymbol}${_appliedCoupon!.originalAmount.toStringAsFixed(2)}',
                    color: theme.canvasColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 6),
                  _PriceRow(
                    label: 'Coupon Discount (${_appliedCoupon!.couponCode})',
                    amount:
                        '-${widget.currencySymbol}${_appliedCoupon!.discountAmount.toStringAsFixed(2)}',
                    color: Colors.green,
                    isDiscount: true,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _PriceRow(
                    label: 'Total Payable',
                    amount:
                        '${widget.currencySymbol}${_appliedCoupon!.finalPayableAmount.toStringAsFixed(2)}',
                    color: theme.primaryColor,
                    isBold: true,
                    fontSize: 15,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isDiscount = false,
    this.isBold = false,
    this.fontSize = 13,
  });

  final String label;
  final String amount;
  final Color color;
  final bool isDiscount;
  final bool isBold;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
