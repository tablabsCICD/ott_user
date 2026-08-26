import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:sms_autofill/sms_autofill.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard>
    with CodeAutoFill, SingleTickerProviderStateMixin {
  static const int _otpLength = 6;
  static const int _resendCooldownSeconds = 60;
  static const Duration _otpAutoFillTimeout = Duration(seconds: 60);

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _mobileFocusNode = FocusNode(debugLabel: 'login-mobile');
  final FocusNode _otpFocusNode = FocusNode(debugLabel: 'login-otp');
  final FocusNode _submitFocusNode = FocusNode(debugLabel: 'login-submit');
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'login-back');
  final FocusNode _resendFocusNode = FocusNode(debugLabel: 'login-resend');
  final FocusNode _skipFocusNode = FocusNode(debugLabel: 'login-skip');
  final List<FocusNode> _keypadFocusNodes = List.generate(
    12,
    (index) => FocusNode(debugLabel: 'login-tv-keypad-$index'),
  );
  final _formKey = GlobalKey<FormState>();

  bool otpSent = false;
  bool isLoading = false;
  bool _authRequestInFlight = false;
  String _mobileNumberForOtp = '';
  int _resendSecondsRemaining = 0;
  bool _isListeningForOtp = false;
  bool _otpAutoFilled = false;
  String? _otpHelperText;
  Timer? _resendTimer;
  Timer? _otpAutoFillTimeoutTimer;
  final Stopwatch _screenLoadWatch = Stopwatch();

  String selectedCode = '+91';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _screenLoadWatch.start();
    _mobileFocusNode.addListener(_handleInputFocusChanged);
    _otpFocusNode.addListener(_handleInputFocusChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        log(
          'Verify OTP/Login screen first frame in ${_screenLoadWatch.elapsedMilliseconds}ms',
          name: 'OtpPerformance',
        );
      }
      if (!mounted) return;
      if (_useTvKeypad(context)) {
        if (_keypadFocusNodes.isNotEmpty) {
          _keypadFocusNodes[0].requestFocus();
        } else {
          _mobileFocusNode.requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    unawaited(_stopOtpAutoFillListener());
    _resendTimer?.cancel();
    _otpAutoFillTimeoutTimer?.cancel();
    _mobileFocusNode.removeListener(_handleInputFocusChanged);
    _otpFocusNode.removeListener(_handleInputFocusChanged);
    _mobileFocusNode.dispose();
    _otpFocusNode.dispose();
    _submitFocusNode.dispose();
    _backFocusNode.dispose();
    _resendFocusNode.dispose();
    _skipFocusNode.dispose();
    for (final node in _keypadFocusNodes) {
      node.dispose();
    }
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    final autoFilledOtp = _extractOtpCode(code ?? '');
    if (autoFilledOtp == null ||
        !mounted ||
        _otpController.text == autoFilledOtp) {
      return;
    }

    _otpController.text = autoFilledOtp;
    _otpController.selection = TextSelection.collapsed(
      offset: _otpController.text.length,
    );
    setState(() {
      _otpAutoFilled = true;
      _otpHelperText = 'OTP detected automatically.';
    });

    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _authRequestInFlight || !otpSent) return;
      _handleLoginOrOtp();
    });
  }

  void _handleInputFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool _useTvKeypad(BuildContext context) {
    return !kIsWeb && ResponsiveWidget.isTv(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final useTvKeypad = _useTvKeypad(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: !(kIsWeb || ResponsiveWidget.isTv(context)),
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: LanguageDropdown(),
          ),
        ],
      ),
      body: Stack(
        children: [
          /// Ambient Cinematic Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.4),
                  radius: 1.2,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.18),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          /// Ambient glow orbs for luxury TV look
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    blurRadius: 150,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: -120,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primaryColor.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.10),
                    blurRadius: 160,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          /// Main Content
          SafeArea(
            child: Focus(
              onKeyEvent: useTvKeypad ? _handleTvCredentialKey : null,
              child: ResponsiveWidget.isTv(context)
                  ? _buildTvLayout(context, lang, theme, useTvKeypad)
                  : _buildMobileLayout(context, lang, theme, useTvKeypad),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TV LAYOUT (Inspired by SonyLIV / Hotstar / ZEE5)
  // ===========================================================================
  Widget _buildTvLayout(
    BuildContext context,
    AppLocalizations lang,
    ThemeData theme,
    bool useTvKeypad,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// Left Side: Brand Showcase & Value Props
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(right: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Brand Logo with Soft Glow
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        ImageConstant.logo,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  /// Dynamic Headline
                  Text(
                    otpSent ? "Verify Mobile Number" : "Sign In to Continue",
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: theme.canvasColor,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Subtitle / Context
                  if (!otpSent) ...[
                    Text(
                      "Enter your mobile number to get instant access to unlimited movies, exclusive originals, and live entertainment.",
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.canvasColor.withValues(alpha: 0.72),
                        height: 1.5,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Text(
                          "Code sent to ",
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.canvasColor.withValues(alpha: 0.72),
                          ),
                        ),
                        Text(
                          "$selectedCode $_mobileNumberForOtp",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OttTvFocus(
                      focusNode: _backFocusNode,
                      borderRadius: 10,
                      scale: 1.05,
                      onTap: () {
                        setState(() {
                          otpSent = false;
                          _otpController.clear();
                          _otpHelperText = null;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _keypadFocusNodes.isNotEmpty) {
                            _keypadFocusNodes[0].requestFocus();
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Change Mobile Number",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 36),

                  /// Feature Badges
                  _buildFeatureBadge(
                    icon: Icons.movie_creation_outlined,
                    title: "Unlimited Entertainment",
                    subtitle: "Stream thousands of blockbuster movies & shows",
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureBadge(
                    icon: Icons.hd_outlined,
                    title: "4K Ultra HD & Dolby Sound",
                    subtitle: "Experience cinema-grade picture and audio",
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureBadge(
                    icon: Icons.devices_outlined,
                    title: "Watch Across Devices",
                    subtitle: "Resume seamlessly on TV, Mobile & Web",
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          /// Right Side: Interactive TV Authentication Card
          Expanded(
            flex: 5,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildTvFormCard(context, lang, theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, color: theme.primaryColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.canvasColor.withValues(alpha: 0.60),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TV FORM CARD
  // ===========================================================================
  Widget _buildTvFormCard(
    BuildContext context,
    AppLocalizations lang,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 36,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// Header indicator inside card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    otpSent ? "ENTER 6-DIGIT OTP" : "ENTER MOBILE NUMBER",
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: theme.primaryColor,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      otpSent ? "STEP 2 OF 2" : "STEP 1 OF 2",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!otpSent) ...[
                /// Mobile Number TV Display Box
                _buildTvMobileDisplayBox(theme),
              ] else ...[
                /// OTP 6-Box TV Slot Display
                _buildTvOtpSlotDisplay(theme),
                if (_otpHelperText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _otpHelperText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _otpAutoFilled
                          ? Colors.greenAccent
                          : theme.canvasColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                /// Resend Timer Action Pill
                Align(
                  alignment: Alignment.centerRight,
                  child: FocusTraversalOrder(
                    order: const NumericFocusOrder(18),
                    child: OttTvFocus(
                      focusNode: _resendFocusNode,
                      borderRadius: 8,
                      scale: 1.05,
                      onTap: isLoading ||
                              _authRequestInFlight ||
                              _resendSecondsRemaining > 0
                          ? null
                          : _resendOtp,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Text(
                          _resendSecondsRemaining > 0
                              ? 'Resend OTP in ${_formatResendTime(_resendSecondsRemaining)}'
                              : 'Resend OTP',
                          style: TextStyle(
                            color: _resendSecondsRemaining > 0
                                ? theme.canvasColor.withValues(alpha: 0.5)
                                : theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              /// On-Screen TV Number Pad
              _TvNumberPad(
                focusNodes: _keypadFocusNodes,
                focusOrderStart: 1,
                onDigit: _appendTvDigit,
                onBackspace: _removeTvDigit,
                onDone: _handleTvDone,
              ),

              const SizedBox(height: 16),

              /// Primary Action Button (Send OTP / Verify OTP)
              FocusTraversalOrder(
                order: const NumericFocusOrder(20),
                child: OttTvFocus(
                  focusNode: _submitFocusNode,
                  borderRadius: 14,
                  scale: 1.04,
                  onTap: isLoading || _authRequestInFlight
                      ? null
                      : _handleLoginOrOtp,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  otpSent ? lang.verifyOtp : lang.sendOtp,
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// Skip Button
              FocusTraversalOrder(
                order: const NumericFocusOrder(21),
                child: OttTvFocus(
                  focusNode: _skipFocusNode,
                  borderRadius: 10,
                  scale: 1.03,
                  semanticLabel: "Skip & Browse App",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NavigationPage(),
                      ),
                    );
                  },
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Skip & Browse App as Guest",
                        style: TextStyle(
                          color: theme.canvasColor.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTvMobileDisplayBox(ThemeData theme) {
    final text = _mobileController.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: text.isNotEmpty
              ? theme.primaryColor.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "🇮🇳 +91",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.canvasColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 24,
            width: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: text.isEmpty
                ? Text(
                    "Enter 10 digit number",
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.canvasColor.withValues(alpha: 0.35),
                      letterSpacing: 1.0,
                    ),
                  )
                : Row(
                    children: [
                      Text(
                        _formatSpacedPhoneNumber(text),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.canvasColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      if (text.length < 10) ...[
                        const SizedBox(width: 4),
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: Container(
                            height: 20,
                            width: 2.5,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          if (text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _mobileController.clear();
                setState(() {});
              },
              child: Icon(
                Icons.cancel,
                color: theme.canvasColor.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  String _formatSpacedPhoneNumber(String value) {
    if (value.length <= 5) return value;
    return '${value.substring(0, 5)} ${value.substring(5)}';
  }

  Widget _buildTvOtpSlotDisplay(ThemeData theme) {
    final otpText = _otpController.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final hasValue = index < otpText.length;
        final isCurrentActive = index == otpText.length;
        final digit = hasValue ? otpText[index] : '';

        return Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: hasValue
                ? theme.primaryColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentActive
                  ? theme.primaryColor
                  : hasValue
                      ? theme.primaryColor.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.15),
              width: isCurrentActive ? 2.2 : 1.2,
            ),
            boxShadow: isCurrentActive
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: hasValue
                ? Text(
                    digit,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.canvasColor,
                    ),
                  )
                : isCurrentActive
                    ? FadeTransition(
                        opacity: _pulseAnimation,
                        child: Container(
                          height: 20,
                          width: 2.5,
                          color: theme.primaryColor,
                        ),
                      )
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
          ),
        );
      }),
    );
  }

  // ===========================================================================
  // MOBILE / TABLET LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations lang,
    ThemeData theme,
    bool useTvKeypad,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: ResponsiveWidget.isMobile(context) ? 80 : 120,
                child: Hero(
                  tag: "logo",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      ImageConstant.logo,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildMobileFormCard(context, lang, theme),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFormCard(
    BuildContext context,
    AppLocalizations lang,
    ThemeData theme,
  ) {
    return Card(
      elevation: 8,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (otpSent) ...[
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        setState(() {
                          otpSent = false;
                          _otpController.clear();
                          _otpHelperText = null;
                        });
                      },
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Verify OTP",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.canvasColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the 6-digit OTP sent to $selectedCode $_mobileNumberForOtp",
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.canvasColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                PinCodeTextField(
                  focusNode: _otpFocusNode,
                  autoDisposeControllers: false,
                  cursorColor: theme.primaryColor,
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  enablePinAutofill: true,
                  animationType: AnimationType.fade,
                  onCompleted: (_) {
                    if (!isLoading && !_authRequestInFlight) {
                      _handleLoginOrOtp();
                    }
                  },
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 48,
                    fieldWidth:
                        ResponsiveWidget.isMobile(context) ? 42 : 48,
                    activeFillColor: theme.cardColor,
                    selectedFillColor: theme.cardColor,
                    inactiveFillColor: theme.cardColor,
                    activeColor: theme.primaryColor,
                    selectedColor: theme.primaryColor,
                    inactiveColor: Colors.grey[600]!,
                  ),
                  backgroundColor: theme.cardColor,
                  enableActiveFill: true,
                  onChanged: (value) {
                    if (_otpAutoFilled && value.length < _otpLength) {
                      setState(() {
                        _otpAutoFilled = false;
                        _otpHelperText = null;
                      });
                    }
                  },
                ),
                if (_otpHelperText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _otpHelperText!,
                    style: TextStyle(
                      color: _otpAutoFilled
                          ? Colors.green
                          : theme.canvasColor.withValues(alpha: 0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isLoading ||
                            _authRequestInFlight ||
                            _resendSecondsRemaining > 0
                        ? null
                        : _resendOtp,
                    child: Text(
                      _resendSecondsRemaining > 0
                          ? 'Resend OTP in ${_formatResendTime(_resendSecondsRemaining)}'
                          : 'Resend OTP',
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  lang.login,
                  style: GoogleFonts.outfit(
                    color: theme.primaryColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Enter your phone number to receive a verification code",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.canvasColor.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                IntlPhoneField(
                  focusNode: _mobileFocusNode,
                  cursorColor: theme.primaryColor,
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (phone) {
                    _mobileNumberForOtp = _digitsOnly(phone.number);
                  },
                  pickerDialogStyle: PickerDialogStyle(
                    backgroundColor: theme.cardColor,
                    searchFieldCursorColor: theme.primaryColor,
                    countryNameStyle: TextStyle(color: theme.canvasColor),
                    countryCodeStyle: TextStyle(color: theme.canvasColor),
                    searchFieldInputDecoration: InputDecoration(
                      filled: true,
                      fillColor: theme.cardColor,
                      counterText: '',
                      hintText: 'Search by country name and code ..',
                      hintStyle: const TextStyle(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                  ),
                  decoration: _loginInputDecoration(
                    theme,
                    lang.enterMobileNumber,
                  ),
                  initialCountryCode: 'IN',
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return 'Please enter a valid mobile number';
                    }
                    return null;
                  },
                  style: const TextStyle(fontSize: 16),
                  dropdownIconPosition: IconPosition.trailing,
                  showDropdownIcon: true,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading || _authRequestInFlight
                      ? null
                      : _handleLoginOrOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          otpSent ? lang.verifyOtp : lang.sendOtp,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NavigationPage(),
                    ),
                  );
                },
                child: Text(
                  "Skip & Browse App",
                  style: TextStyle(
                    color: theme.canvasColor.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _loginInputDecoration(ThemeData theme, String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: theme.cardColor,
      counterText: '',
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[600]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
    );
  }

  // ===========================================================================
  // BUSINESS LOGIC: OTP SEND / VERIFY
  // ===========================================================================
  void _handleLoginOrOtp() async {
    if (_authRequestInFlight) return;
    final mobile = _normalizedMobileForAuth();
    if (mobile.length < 10) {
      CustomToast.show(
        context,
        'Please enter a valid 10-digit mobile number',
        isSuccess: false,
      );
      return;
    }
    final lang = AppLocalizations.of(context)!;
    _authRequestInFlight = true;
    setState(() => isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final actionWatch = Stopwatch()..start();

    try {
      if (!otpSent) {
        final result = await userProvider.sendOTP(mobile);
        _logOtpPerformance(
          'Send OTP action completed in ${actionWatch.elapsedMilliseconds}ms',
        );
        if (!mounted) return;

        final bool success = result?['success'] == true;
        final String message = result?['message'] ?? 'Something went wrong';

        if (success) {
          CustomToast.show(
            context,
            '${lang.otpSentSuccessfully} ($mobile)',
            isSuccess: true,
          );
          setState(() {
            otpSent = true;
            _mobileNumberForOtp = mobile;
          });
          _otpController.clear();
          _otpAutoFilled = false;
          _startResendCooldown();
          await _startOtpAutoFillListener();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _keypadFocusNodes.isNotEmpty) {
              _keypadFocusNodes[0].requestFocus();
            }
          });
        } else {
          CustomToast.show(
            context,
            'Failure: $message',
            isSuccess: false,
          );
        }
      } else {
        final otp = _digitsOnly(_otpController.text);

        if (otp.length != _otpLength) {
          CustomToast.show(context, 'Please enter a 6-digit OTP',
              isSuccess: false);
          return;
        }

        final result = await userProvider.verifyOTP(
          mobile,
          otp,
          context: context,
        );
        _logOtpPerformance(
          'Verify OTP action completed in ${actionWatch.elapsedMilliseconds}ms',
        );
        if (!mounted) return;

        final bool success = result['success'] == true;
        final String message = result['message']?.toString() ?? 'Invalid OTP';

        if (success) {
          unawaited(_stopOtpAutoFillListener());
          CustomToast.show(
            context,
            'Welcome! You have signed in successfully.',
            isSuccess: true,
          );

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const NavigationPage(),
            ),
            (route) => false,
          );
        } else {
          CustomToast.show(
            context,
            'Failure: $message',
            isSuccess: false,
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrintStack(label: 'OTP Auth Error', stackTrace: stackTrace);
      if (!mounted) return;
      CustomToast.show(
        context,
        'Something went wrong. Please try again.',
        isSuccess: false,
      );
    } finally {
      _authRequestInFlight = false;
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_authRequestInFlight) return;
    final mobile = _normalizedMobileForAuth();
    if (mobile.length < 10) {
      CustomToast.show(
        context,
        'Please enter a valid mobile number',
        isSuccess: false,
      );
      return;
    }

    final lang = AppLocalizations.of(context)!;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _authRequestInFlight = true;
    setState(() {
      isLoading = true;
      _otpHelperText = 'Requesting a new OTP...';
    });

    try {
      final result = await userProvider.sendOTP(mobile);
      if (!mounted) return;

      final success = result?['success'] == true;
      final message = result?['message']?.toString() ?? 'Something went wrong';
      if (!success) {
        CustomToast.show(context, 'Failure: $message', isSuccess: false);
        setState(() => _otpHelperText = null);
        return;
      }

      _otpController.clear();
      _otpAutoFilled = false;
      _mobileNumberForOtp = mobile;
      _startResendCooldown();
      await _startOtpAutoFillListener();
      CustomToast.show(
        context,
        '${lang.otpSentSuccessfully} ($mobile)',
        isSuccess: true,
      );
      if (mounted) {
        setState(() => _otpHelperText = 'Waiting for OTP SMS...');
      }
    } catch (error, stackTrace) {
      debugPrintStack(label: 'Resend OTP Error', stackTrace: stackTrace);
      if (!mounted) return;
      CustomToast.show(
        context,
        'Unable to resend OTP. Please try again.',
        isSuccess: false,
      );
    } finally {
      _authRequestInFlight = false;
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _startOtpAutoFillListener() async {
    await _stopOtpAutoFillListener();
    if (kIsWeb) return;

    try {
      final appSignature = await SmsAutoFill().getAppSignature;
      if (kDebugMode && appSignature.isNotEmpty) {
        debugPrint('Android SMS Retriever app signature: $appSignature');
      }
      listenForCode(smsCodeRegexPattern: r'\d{6}');
      _otpAutoFillTimeoutTimer = Timer(_otpAutoFillTimeout, () {
        if (!mounted || !_isListeningForOtp) return;
        unawaited(_stopOtpAutoFillListener());
        if (mounted && otpSent && _otpController.text.length < _otpLength) {
          setState(() {
            _otpHelperText =
                'Auto-fill timed out. Please enter the OTP manually.';
          });
        }
      });
      if (mounted) {
        setState(() {
          _isListeningForOtp = true;
          _otpHelperText = 'Waiting for OTP SMS...';
        });
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('OTP auto-fill listener failed: $error');
      }
      if (mounted) {
        setState(() {
          _isListeningForOtp = false;
          _otpHelperText =
              'Auto-fill is unavailable. Please enter the OTP manually.';
        });
      }
    }
  }

  Future<void> _stopOtpAutoFillListener() async {
    _otpAutoFillTimeoutTimer?.cancel();
    _otpAutoFillTimeoutTimer = null;
    if (_isListeningForOtp) {
      await cancel();
      await unregisterListener();
    }
    _isListeningForOtp = false;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
        return;
      }
      setState(() => _resendSecondsRemaining--);
    });
  }

  void _logOtpPerformance(String message) {
    if (!kDebugMode) return;
    log(message, name: 'OtpPerformance');
  }

  String _normalizedMobileForAuth() {
    final fromPhoneField = _digitsOnly(_mobileNumberForOtp);
    if (fromPhoneField.isNotEmpty) return fromPhoneField;
    return _digitsOnly(_mobileController.text);
  }

  String _formatResendTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final remainingSeconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _digitsOnly(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String? _extractOtpCode(String value) {
    final match = RegExp(r'\d{6}').firstMatch(value);
    return match?.group(0);
  }

  void _appendTvDigit(String digit) {
    final controller = otpSent ? _otpController : _mobileController;
    final maxLength = otpSent ? 6 : 10;
    final current = controller.text;
    if (current.length >= maxLength) return;

    controller.text = '$current$digit';
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    setState(() {});

    if (otpSent && controller.text.length == 6) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !isLoading && !_authRequestInFlight) {
          _handleLoginOrOtp();
        }
      });
    }
  }

  void _removeTvDigit() {
    final controller = otpSent ? _otpController : _mobileController;
    final current = controller.text;
    if (current.isEmpty) return;

    controller.text = current.substring(0, current.length - 1);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    setState(() {});
  }

  KeyEventResult _handleTvCredentialKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.gameButtonA) {
      if (_mobileFocusNode.hasFocus || _otpFocusNode.hasFocus) {
        _handleTvDone();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  bool get _currentTvCredentialIsComplete {
    if (otpSent) {
      return _digitsOnly(_otpController.text).length == _otpLength;
    }
    return _digitsOnly(_mobileController.text).length == 10;
  }

  void _handleTvDone() {
    if (isLoading || _authRequestInFlight) return;
    if (_currentTvCredentialIsComplete) {
      _handleLoginOrOtp();
      return;
    }
    _handleLoginOrOtp();
  }
}

// =============================================================================
// TV NUMBER PAD COMPONENT
// =============================================================================
class _TvNumberPad extends StatelessWidget {
  const _TvNumberPad({
    required this.focusNodes,
    required this.focusOrderStart,
    required this.onDigit,
    required this.onBackspace,
    required this.onDone,
  });

  final List<FocusNode> focusNodes;
  final double focusOrderStart;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = <_TvNumberPadKey>[
      for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
        _TvNumberPadKey(label: digit, onTap: () => onDigit(digit)),
      _TvNumberPadKey(
        icon: Icons.backspace_outlined,
        isAction: true,
        actionColor: Colors.orangeAccent,
        onTap: onBackspace,
      ),
      _TvNumberPadKey(label: '0', onTap: () => onDigit('0')),
      _TvNumberPadKey(
        icon: Icons.check_circle_outline_rounded,
        isAction: true,
        actionColor: Colors.greenAccent,
        onTap: onDone,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return FocusTraversalOrder(
          order: NumericFocusOrder(focusOrderStart + index),
          child: OttTvFocus(
            focusNode: focusNodes[index],
            onTap: key.onTap,
            borderRadius: 12,
            scale: 1.08,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: key.icon == null
                    ? Text(
                        key.label!,
                        style: GoogleFonts.outfit(
                          color: theme.canvasColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(
                        key.icon,
                        color: key.actionColor ?? theme.canvasColor,
                        size: 22,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TvNumberPadKey {
  const _TvNumberPadKey({
    this.label,
    this.icon,
    this.isAction = false,
    this.actionColor,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool isAction;
  final Color? actionColor;
  final VoidCallback onTap;
}
