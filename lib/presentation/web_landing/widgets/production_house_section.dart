import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/utils/text_capitalization_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:ott/app/core/services/email_service.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductionHouseSection extends StatelessWidget {
  const ProductionHouseSection({
    super.key,
    required this.onRegister,
    required this.onLearnMore,
  });

  final VoidCallback onRegister;
  final VoidCallback onLearnMore;

  static final Uri _whatsAppUri = Uri.parse('https://wa.me/919145451291');

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
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1080;
    final horizontalPadding = isMobile ? 18.0 : (isTablet ? 32.0 : 56.0);
    final isStacked = width < 1080;

    final steps = [
      (
        stepNum: 1,
        title: lang.registerProductionHouse,
        subtitle: lang.contentManagement,
        icon: Icons.app_registration_rounded,
      ),
      (
        stepNum: 2,
        title: lang.completeVerification,
        subtitle: lang.approvalWorkflow,
        icon: Icons.verified_user_rounded,
      ),
      (
        stepNum: 3,
        title: lang.uploadMoviesSeries,
        subtitle: lang.secureDistribution,
        icon: Icons.video_call_rounded,
      ),
      (
        stepNum: 4,
        title: lang.trackRevenuePerformance,
        subtitle: lang.reachGlobalAudience,
        icon: Icons.auto_graph_rounded,
      ),
    ];

    final modules = [
      lang.contentManagement,
      lang.approvalWorkflow,
      lang.releaseScheduling,
      lang.revenueTracking,
      lang.analyticsDashboard,
      lang.secureDistribution,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        isMobile ? 42 : 64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            lang.productionHousesTitle,
            style: FilmytellTheme.font(
              color: FilmytellTheme.textPrimary,
              fontSize: isMobile ? 28 : (isTablet ? 34 : 40),
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          // Section Description
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              lang.productionHouseDescription,
              style: FilmytellTheme.bodyLarge(
                isMobile: isMobile,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Module Capability Badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final module in modules) _ModuleBadge(label: module),
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons Bar
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StudioPrimaryButton(
                label: lang.registerProductionHouse,
                onPressed: onRegister,
              ),
              _StudioSecondaryButton(
                label: lang.learnMore,
                onPressed: onLearnMore,
              ),
              _WhatsAppChatButton(
                label: lang.chatWithUsWhatsapp,
                onPressed: () => _openWhatsApp(context),
              ),
            ],
          ),
          const SizedBox(height: 36),
          // Studio Publishing Workflow + Enquiry Form (De-containerized layout)
          if (isStacked) ...[
            _StepsGridView(steps: steps, isSideBySide: false),
            const SizedBox(height: 30),
            const _ProductionHouseEnquiryCard(),
          ] else ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 12,
                    child: _StepsGridView(steps: steps, isSideBySide: true),
                  ),
                  const SizedBox(width: 32),
                  const Expanded(
                    flex: 9,
                    child: _ProductionHouseEnquiryCard(),
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

class _StepsGridView extends StatelessWidget {
  const _StepsGridView({required this.steps, this.isSideBySide = false});

  final List<
      ({
        IconData icon,
        int stepNum,
        String subtitle,
        String title,
      })> steps;
  final bool isSideBySide;

  @override
  Widget build(BuildContext context) {
    if (isSideBySide && steps.length == 4) {
      return Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StudioStepCard(
                    index: steps[0].stepNum,
                    label: steps[0].title,
                    subtitle: steps[0].subtitle,
                    icon: steps[0].icon,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StudioStepCard(
                    index: steps[1].stepNum,
                    label: steps[1].title,
                    subtitle: steps[1].subtitle,
                    icon: steps[1].icon,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StudioStepCard(
                    index: steps[2].stepNum,
                    label: steps[2].title,
                    subtitle: steps[2].subtitle,
                    icon: steps[2].icon,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StudioStepCard(
                    index: steps[3].stepNum,
                    label: steps[3].title,
                    subtitle: steps[3].subtitle,
                    icon: steps[3].icon,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCol = constraints.maxWidth >= 480;
        final crossAxisCount = isTwoCol ? 2 : 1;
        final aspectRatio = isTwoCol ? 1.85 : 2.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final step = steps[index];
            return _StudioStepCard(
              index: step.stepNum,
              label: step.title,
              subtitle: step.subtitle,
              icon: step.icon,
            );
          },
        );
      },
    );
  }
}

class _StudioStepCard extends StatefulWidget {
  const _StudioStepCard({
    required this.index,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final int index;
  final String label;
  final String subtitle;
  final IconData icon;

  @override
  State<_StudioStepCard> createState() => _StudioStepCardState();
}

class _StudioStepCardState extends State<_StudioStepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              _hovered ? FilmytellTheme.primaryHover : FilmytellTheme.primary,
          border: Border.all(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.25),
            width: _hovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: FilmytellTheme.primary
                  .withValues(alpha: _hovered ? 0.45 : 0.25),
              blurRadius: _hovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Step Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                //  color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '${AppLocalizations.of(context)!.step} 0${widget.index}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 7),
            // Step Action Title
            Text(
              widget.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FilmytellTheme.font(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            // Step Subtitle / Description
            Expanded(
              child: Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FilmytellTheme.font(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12.5,
                  height: 1.32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Bottom-Right Positioned Step Icon (Netflix "More reasons to join" layout)
            Align(
              alignment: Alignment.bottomRight,
              child: AnimatedScale(
                scale: _hovered ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Colors.white.withValues(alpha: _hovered ? 0.28 : 0.18),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: _hovered ? 0.65 : 0.35),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
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

  String? _validateRequired(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  String? _validateEmail(String? value) {
    final lang = AppLocalizations.of(context)!;
    final email = (value ?? '').trim();
    if (email.isEmpty) return lang.enterEmailAddress;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return lang.enterValidEmailAddress;
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final lang = AppLocalizations.of(context)!;
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return lang.enterPhoneNumber;
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(phone)) {
      return lang.enterValidPhoneNumber;
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
          AppLocalizations.of(context)!.failedToSendEmail,
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
        AppLocalizations.of(context)!.emailSentSuccessfully,
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
      fillColor: Colors.black.withValues(alpha: 0.50),
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      errorStyle: const TextStyle(fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_sending,
      keyboardType: keyboardType,
      inputFormatters: [
        ...?inputFormatters,
        if (textCapitalization == TextCapitalization.words)
          CapitalizeWordsTextInputFormatter(),
        if (textCapitalization == TextCapitalization.sentences)
          CapitalizeSentencesTextInputFormatter(),
      ],
      textCapitalization: textCapitalization,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      style: const TextStyle(
        color: FilmytellTheme.textPrimary,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
      ),
      decoration: _fieldDecoration(
        hint: hint,
        accentColor: accentColor,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _hovered ? const Color(0xFF222C5A) : const Color(0xFF192247),
              _hovered ? const Color(0xFF2E1523) : const Color(0xFF210E17),
            ],
          ),
          border: Border.all(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.12),
            width: _hovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.70 : 0.50),
              blurRadius: _hovered ? 22 : 16,
              offset: const Offset(0, 6),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: FilmytellTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FilmytellTheme.primary,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang.haveQuestionHelp,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _inputField(
                controller: _emailController,
                hint: lang.email,
                accentColor: FilmytellTheme.primary,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              _inputField(
                controller: _phoneController,
                hint: lang.phoneNumber,
                accentColor: FilmytellTheme.primary,
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
                hint: lang.message,
                accentColor: FilmytellTheme.primary,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) => _validateRequired(
                  value,
                  lang.enterMessage,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: lang.sendProductionEnquiry,
                  child: ElevatedButton.icon(
                    onPressed: _sending ? null : _submitEnquiry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FilmytellTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          FilmytellTheme.primary.withValues(alpha: 0.55),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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
                        : const Icon(Icons.send_rounded, size: 17),
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

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: FilmytellTheme.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StudioPrimaryButton extends StatefulWidget {
  const _StudioPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_StudioPrimaryButton> createState() => _StudioPrimaryButtonState();
}

class _StudioPrimaryButtonState extends State<_StudioPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _hovered
                ? const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFE50914)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFE50914)],
                  ),
            boxShadow: [
              BoxShadow(
                color: FilmytellTheme.primary
                    .withValues(alpha: _hovered ? 0.45 : 0.24),
                blurRadius: _hovered ? 18 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _StudioSecondaryButton extends StatefulWidget {
  const _StudioSecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_StudioSecondaryButton> createState() => _StudioSecondaryButtonState();
}

class _StudioSecondaryButtonState extends State<_StudioSecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: _hovered
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            foregroundColor: Colors.white,
            side: BorderSide(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.50)
                  : Colors.white.withValues(alpha: 0.28),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}

class _WhatsAppChatButton extends StatefulWidget {
  const _WhatsAppChatButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_WhatsAppChatButton> createState() => _WhatsAppChatButtonState();
}

class _WhatsAppChatButtonState extends State<_WhatsAppChatButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: OutlinedButton.icon(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: _hovered
                ? const Color(0xFF25D366).withValues(alpha: 0.12)
                : Colors.transparent,
            foregroundColor: Colors.white,
            side: BorderSide(
              color: _hovered
                  ? const Color(0xFF25D366)
                  : const Color(0xFF25D366).withValues(alpha: 0.70),
              width: 1.2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: SvgPicture.asset(
            'assets/icons/whatsapp.svg',
            width: 20,
            height: 20,
          ),
          label: Text(widget.label),
        ),
      ),
    );
  }
}
