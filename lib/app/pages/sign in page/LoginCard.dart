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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:ott/app/core/services/referral_service.dart';

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
  String? _pendingReferralCode;

  String selectedCode = '+91';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _screenLoadWatch.start();
    _mobileFocusNode.addListener(_handleInputFocusChanged);
    _otpFocusNode.addListener(_handleInputFocusChanged);
    _checkPendingReferralCode();
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

  void _showTextInputKeyboard(FocusNode node) {
    node.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  Future<void> _checkPendingReferralCode() async {
    final code = await ReferralService.instance.getPendingReferralCode();
    if (mounted && code != _pendingReferralCode) {
      setState(() {
        _pendingReferralCode = code;
      });
    }
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
      body: Focus(
        onKeyEvent: useTvKeypad ? _handleTvCredentialKey : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: ResponsiveWidget.isMobile(context) ? 90 : 130,
                  child: Hero(
                    tag: "logo",
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(25),
                      child: Image.asset(
                        ImageConstant.logo,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: ResponsiveWidget.isMobile(context) ? 24 : 24,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 6,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      child: FocusTraversalGroup(
                        policy: OrderedTraversalPolicy(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (otpSent) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LoginCard()));
                                      },
                                      icon: Icon(
                                        Icons.arrow_back_ios_new_sharp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              Text(
                                lang.login,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_pendingReferralCode != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          theme.primaryColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.card_giftcard,
                                        size: 16,
                                        color: theme.primaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Referral Code: $_pendingReferralCode',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 15),

                              // Phone number row
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      lang.mobileNumber,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (useTvKeypad)
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(1),
                                  child: _TvFocusFrame(
                                    focusNode: _mobileFocusNode,
                                    enabled: useTvKeypad,
                                    child: TextFormField(
                                      focusNode: _mobileFocusNode,
                                      readOnly: otpSent,
                                      showCursor: true,
                                      cursorColor: theme.primaryColor,
                                      controller: _mobileController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onChanged: (value) {
                                        _mobileNumberForOtp =
                                            _digitsOnly(value).trim();
                                      },
                                      onFieldSubmitted: (_) {
                                        if (!isLoading &&
                                            !_authRequestInFlight) {
                                          _handleLoginOrOtp();
                                        }
                                      },
                                      decoration: _loginInputDecoration(
                                        theme,
                                        lang.enterMobileNumber,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a valid mobile number';
                                        }

                                        return null;
                                      },
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                              else
                                IntlPhoneField(
                                  focusNode: _mobileFocusNode,
                                  readOnly: otpSent,
                                  cursorColor: theme.primaryColor,
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (phone) {
                                    _mobileNumberForOtp =
                                        _digitsOnly(phone.number);
                                  },

                                  pickerDialogStyle: PickerDialogStyle(
                                    backgroundColor: theme.cardColor,
                                    searchFieldCursorColor: theme.primaryColor,
                                    countryNameStyle: TextStyle(
                                      color: theme.canvasColor,
                                    ),
                                    countryCodeStyle: TextStyle(
                                      color: theme.canvasColor,
                                    ),
                                    searchFieldInputDecoration: InputDecoration(
                                        filled: true,
                                        fillColor: theme.cardColor,
                                        counterText: '',
                                        hintText:
                                            'Search by country name and code ..',
                                        hintStyle:
                                            const TextStyle(fontSize: 14),
                                        // Border properties for search in dropdown
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                              color: Colors.grey[
                                                  400]!), // Default border color
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                              color: Colors.grey[
                                                  400]!), // Border color when enabled
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          borderSide: BorderSide(
                                              color: theme.primaryColor,
                                              width:
                                                  2), // Border color when focused
                                        ),
                                        prefixIcon: Icon(Icons.search)),
                                  ),
                                  decoration: _loginInputDecoration(
                                    theme,
                                    lang.enterMobileNumber,
                                  ),
                                  initialCountryCode: 'IN', // Default to India
                                  validator: (phone) {
                                    if (phone == null || phone.number.isEmpty) {
                                      return 'Please enter a valid mobile number';
                                    }

                                    return null;
                                  },
                                  //invalidNumberMessage: 'Invalid Number',
                                  style: const TextStyle(fontSize: 16),
                                  dropdownIconPosition: IconPosition.trailing,
                                  showDropdownIcon: true,
                                ),

                              // CustomTextField(
                              //   controller: _mobileController,
                              //   hintText: 'Enter mobile number',
                              //   label: 'Mobile Number',
                              //   textInputType: TextInputType.phone,
                              //   isPhoneNumber: true,
                              //   isValidator: true,
                              // ),
                              const SizedBox(height: 25),

                              /// OTP input
                              if (otpSent) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    lang.enterOtp,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FocusTraversalOrder(
                                  order: const NumericFocusOrder(2),
                                  child: _TvFocusFrame(
                                    focusNode: _otpFocusNode,
                                    enabled: useTvKeypad,
                                    child: PinCodeTextField(
                                      focusNode: _otpFocusNode,
                                      autoDisposeControllers: false,
                                      autoUnfocus: false,
                                      autoDismissKeyboard: false,
                                      readOnly: false,
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
                                      onTap: () =>
                                          _showTextInputKeyboard(_otpFocusNode),
                                      onCompleted: (_) {
                                        if (!isLoading &&
                                            !_authRequestInFlight) {
                                          _handleLoginOrOtp();
                                        }
                                      },
                                      pinTheme: PinTheme(
                                        shape: PinCodeFieldShape.box,
                                        borderRadius: BorderRadius.circular(8),
                                        fieldHeight: 50,
                                        fieldWidth:
                                            ResponsiveWidget.isMobile(context)
                                                ? 40
                                                : 45,
                                        activeFillColor: theme.cardColor,
                                        selectedFillColor: theme.cardColor,
                                        inactiveFillColor: theme.cardColor,
                                        activeColor: theme.primaryColor,
                                        selectedColor: theme.primaryColor,
                                        inactiveColor: Colors.grey[400]!,
                                      ),
                                      backgroundColor: theme.cardColor,
                                      enableActiveFill: true,
                                      onChanged: (value) {
                                        if (_otpAutoFilled &&
                                            value.length < _otpLength) {
                                          setState(() {
                                            _otpAutoFilled = false;
                                            _otpHelperText = null;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                if (_otpHelperText != null) ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _otpHelperText!,
                                      style: TextStyle(
                                        color: _otpAutoFilled
                                            ? Colors.green
                                            : theme.canvasColor
                                                .withOpacity(0.65),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],

                              if (useTvKeypad) ...[
                                _TvNumberPad(
                                  focusNodes: _keypadFocusNodes,
                                  focusOrderStart: 3,
                                  onDigit: _appendTvDigit,
                                  onBackspace: _removeTvDigit,
                                  onDone: () => _submitFocusNode.requestFocus(),
                                ),
                                const SizedBox(height: 20),
                              ],

                              /// Button
                              SizedBox(
                                width: double.infinity,
                                child: FocusTraversalOrder(
                                  order: const NumericFocusOrder(20),
                                  child: _TvFocusFrame(
                                    focusNode: _submitFocusNode,
                                    enabled: useTvKeypad,
                                    child: ElevatedButton(
                                      focusNode: _submitFocusNode,
                                      onPressed:
                                          isLoading || _authRequestInFlight
                                              ? null
                                              : _handleLoginOrOtp,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                              otpSent
                                                  ? lang.verifyOtp
                                                  : lang.sendOtp,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
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
                    ),
                  ),
                ),
              ],
            ),
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
          referralCode: _pendingReferralCode,
        );
        _logOtpPerformance(
          'Verify OTP action completed in ${actionWatch.elapsedMilliseconds}ms',
        );
        if (!mounted) return;

        final bool success = result['success'] == true;
        final String message = result['message']?.toString() ?? 'Invalid OTP';

        if (success) {
          await _stopOtpAutoFillListener();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          if (!mounted) return;

          setState(() {
            // _initializePromoterLevel();
          });
          // Sync user languages into LanguageProvider
          final user = userProvider.userObj;
          final langProvider =
              Provider.of<LanguageProvider>(context, listen: false);
          langProvider.setUserLanguages(user.selectedLanguages ?? []);
          log(user.selectedLanguages.toString());

          CustomToast.show(context, lang.loginSuccessfully, isSuccess: true);
          final navigationWatch = Stopwatch()..start();
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
    } catch (e) {
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
    } catch (_) {
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

      if (kDebugMode && appSignature.isNotEmpty) {}
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
      if (kDebugMode) {}
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

class _TvFocusFrame extends StatelessWidget {
  const _TvFocusFrame({
    required this.child,
    this.focusNode,
    this.enabled = true,
  });

  final Widget child;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return OttTvFocus(
      focusNode: focusNode,
      enabled: enabled,
      child: child,
    );
  }
}

