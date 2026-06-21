import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/core/services/email_service.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductionHouseSection extends StatelessWidget {
  const ProductionHouseSection({
    super.key,
    required this.onRegister,
    required this.onLearnMore,
  });

  final VoidCallback onRegister;
  final VoidCallback onLearnMore;

  static final Uri _whatsAppUri = Uri.parse('https://wa.me/919112012291');

  Future<void> _openWhatsApp(BuildContext context) async {
    final opened = await launchUrl(
      _whatsAppUri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (opened) return;

    final fallbackOpened = await launchUrl(
      _whatsAppUri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!context.mounted || fallbackOpened) return;
    CustomToast.show(
      context,
      AppLocalizations.of(context)!.unableOpenLink,
      isSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final steps = [
      lang.registerProductionHouse,
      lang.completeVerification,
      lang.uploadMoviesSeries,
      lang.submitForApproval,
      lang.trackRevenuePerformance,
      lang.reachGlobalAudience,
    ];
    final modules = [
      lang.contentManagement,
      lang.revenueTracking,
      lang.analyticsDashboard,
      lang.approvalWorkflow,
      lang.releaseScheduling,
      lang.secureDistribution,
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(56, 8, 56, 70),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF101010),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.070),
            Colors.white.withOpacity(0.032),
            Colors.black.withOpacity(0.16),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.productionHouseWorks,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  lang.productionHousesTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  lang.productionHouseDescription,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final module in modules)
                      _ModuleBadge(label: module, color: theme.primaryColor),
                  ],
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(lang.registerProductionHouse),
                    ),
                    OutlinedButton(
                      onPressed: onLearnMore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(lang.learnMore),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF25D366)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: SvgPicture.asset(
                        'assets/icons/whatsapp.svg',
                        width: 22,
                        height: 22,
                      ),
                      label: Text(lang.chatWithUsWhatsapp),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _ProductionHouseEnquiryCard(),
              ],
            ),
          ),
          const SizedBox(width: 42),
          Expanded(
            flex: 9,
            child: Column(
              children: [
                for (int i = 0; i < steps.length; i++)
                  _TimelineRow(
                    index: i + 1,
                    label: steps[i],
                    color: theme.primaryColor,
                    isLast: i == steps.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductionHouseEnquiryCard extends StatefulWidget {
  const _ProductionHouseEnquiryCard();

  @override
  State<_ProductionHouseEnquiryCard> createState() =>
      _ProductionHouseEnquiryCardState();
}

class _ProductionHouseEnquiryCardState
    extends State<_ProductionHouseEnquiryCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final EmailService _emailService = EmailService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _messageController = TextEditingController();
  bool _hovered = false;
  bool _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();

    _messageController.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Please enter email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return 'Please enter phone number';
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String _buildEnquiryMessage() {
    final submittedAt = DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.now(),
    );

    return '''A new enquiry has been submitted.

Email: ${_emailController.text.trim()}
Phone Number: ${_phoneController.text.trim()}
Message: ${_messageController.text.trim()}
Submitted At: $submittedAt''';
  }

  Future<void> _submitEnquiry() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _sending = true);

    try {
      final sent = await _emailService.sendEmail(
        subject: 'New Enquiry Received from Website',
        message: _buildEnquiryMessage(),
      );

      if (!mounted) return;
      if (!sent) {
        CustomToast.show(
          context,
          'Failed to send email. Please try again.',
          isSuccess: false,
        );
        return;
      }

      _emailController.clear();
      _phoneController.clear();
      _messageController.clear();
      _formKey.currentState?.reset();
      CustomToast.show(
        context,
        'Email sent successfully.',
        isSuccess: true,
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required Color accentColor,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: Colors.black.withOpacity(0.28),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.45),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      errorStyle: const TextStyle(fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: accentColor, width: 1.4),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required Color accentColor,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_sending,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      style: const TextStyle(color: Colors.white),
      decoration: _fieldDecoration(
        hint: hint,
        accentColor: accentColor,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF151515).withOpacity(_hovered ? 0.94 : 0.86),
              const Color(0xFF0D0D0D).withOpacity(_hovered ? 0.96 : 0.90),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.primaryColor.withOpacity(_hovered ? 0.48 : 0.24),
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.13),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.48),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lang.haveQuestionHelp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _inputField(
                controller: _emailController,
                hint: 'Email',
                accentColor: theme.primaryColor,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: _phoneController,
                hint: 'Phone Number',
                accentColor: theme.primaryColor,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: _messageController,
                hint: 'Message',
                accentColor: theme.primaryColor,
                minLines: 2,
                maxLines: 4,
                validator: (value) => _validateRequired(
                  value,
                  'Please enter message',
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: lang.sendProductionEnquiry,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submitEnquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          theme.primaryColor.withOpacity(0.55),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _sending
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.help_outline_rounded, size: 19),
                    label: Text(_sending ? 'Sending...' : lang.sendEnquiry),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatefulWidget {
  const _TimelineRow({
    required this.index,
    required this.label,
    required this.color,
    required this.isLast,
  });

  final int index;
  final String label;
  final Color color;
  final bool isLast;

  @override
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    const cardHeight = 54.0;
    const circleSize = 34.0;
    const rowGap = 18.0;
    const circleTop = (cardHeight - circleSize) / 2;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: circleSize,
            height: widget.isLast ? cardHeight : cardHeight + rowGap,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: circleTop + circleSize,
                  child: widget.isLast
                      ? const SizedBox.shrink()
                      : Container(
                          height: rowGap,
                          width: 1,
                          color: Colors.white.withOpacity(0.14),
                        ),
                ),
                Positioned(
                  top: circleTop,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: circleSize,
                    width: circleSize,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? widget.color
                          : Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: widget.color.withOpacity(0.55)),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: cardHeight,
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : rowGap),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_hovered ? 0.42 : 0.26),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: Colors.white.withOpacity(_hovered ? 0.18 : 0.08)),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.82),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
