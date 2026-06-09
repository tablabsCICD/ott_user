import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/route/routes/app_routes.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginCard extends StatefulWidget {
  const LoginCard({super.key});

  @override
  State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _mobileFocusNode = FocusNode(debugLabel: 'login-mobile');
  final FocusNode _otpFocusNode = FocusNode(debugLabel: 'login-otp');
  final FocusNode _submitFocusNode = FocusNode(debugLabel: 'login-submit');
  final List<FocusNode> _keypadFocusNodes = List.generate(
    12,
    (index) => FocusNode(debugLabel: 'login-tv-keypad-$index'),
  );
  final _formKey = GlobalKey<FormState>();

  bool otpSent = false;
  bool isLoading = false;
  bool _editingOtp = false;

  String selectedCode = '+91';
  final List<String> countryCodes = ['+91', '+1', '+44', '+61', '+971'];

  @override
  void initState() {
    //_initializePromoterLevel();
    super.initState();
    _mobileFocusNode.addListener(_handleInputFocusChanged);
    _otpFocusNode.addListener(_handleInputFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _useTvKeypad(context)) {
        _mobileFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _mobileFocusNode.removeListener(_handleInputFocusChanged);
    _otpFocusNode.removeListener(_handleInputFocusChanged);
    _mobileFocusNode.dispose();
    _otpFocusNode.dispose();
    _submitFocusNode.dispose();
    for (final node in _keypadFocusNodes) {
      node.dispose();
    }
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _handleInputFocusChanged() {
    if (!mounted) return;
    if (_otpFocusNode.hasFocus) {
      setState(() => _editingOtp = true);
    } else if (_mobileFocusNode.hasFocus) {
      setState(() => _editingOtp = false);
    }
  }

  // Future<void> _initializePromoterLevel() async {
  //   final promoter =
  //       await LocalSharePreferences.localSharePreferences.getPromoter();

  //   if (promoter != null && promoter.level != null) {
  //     final promoterLevel = _getPromoterLevelEnum(promoter.level!);

  //     if (promoterLevel != null) {
  //       // Update Provider
  //       Provider.of<PromoterProvider>(context, listen: false)
  //           .updateLevel(promoterLevel);

  //       // Store level in SharedPreferences as a string
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('promoterLevel', promoter.level!);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final useTvKeypad = _useTvKeypad(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LanguageDropdown(),
          ),
        ],
      ),
      body: Focus(
        onKeyEvent: useTvKeypad ? _handleTvCredentialKey : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: ResponsiveWidget.isMobile(context) ? 90 : 150,
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
                    height: 60,
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
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) {
                                      if (!isLoading) _handleLoginOrOtp();
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
                                      hintStyle: const TextStyle(fontSize: 14),
                                      // Border properties for search in dropdown
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                            color: Colors.grey[
                                                400]!), // Default border color
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                            color: Colors.grey[
                                                400]!), // Border color when enabled
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
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
                                  lang.sendOtp,
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
                                    animationType: AnimationType.fade,
                                    onCompleted: (_) {
                                      if (!isLoading) _handleLoginOrOtp();
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
                                    onChanged: (_) {},
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
                                        isLoading ? null : _handleLoginOrOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                  SizedBox(
                    height: ResponsiveWidget.isMobile(context) ? 150 : 60,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dropdown styled like CustomTextField
  InputDecoration _loginInputDecoration(ThemeData theme, String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: theme.cardColor,
      counterText: '',
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey[400]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
    );
  }

  bool _useTvKeypad(BuildContext context) {
    return !kIsWeb && ResponsiveWidget.isTv(context);
  }

  // OTP send/verify logic
  void _handleLoginOrOtp() async {
    if (!_formKey.currentState!.validate() || _mobileController.text.isEmpty) {
      return;
    }
    final lang = AppLocalizations.of(context)!;

    setState(() => isLoading = true);

    final mobile = _mobileController.text.trim();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);

    try {
      if (!otpSent) {
        final result = await userProvider.sendOTP(mobile);

        final bool success = result?['success'] == true;
        final String message = result?['message'] ?? 'Something went wrong';

        if (success) {
          CustomToast.show(
            context,
            '${lang.otpSentSuccessfully} ($mobile)',
            isSuccess: true,
          );
          setState(() => otpSent = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _otpFocusNode.requestFocus();
          });
        } else {
          CustomToast.show(
            context,
            'Failure: $message',
            isSuccess: false,
          );
        }
      } else {
        final otp = _otpController.text.trim();

        if (otp.length != 6) {
          CustomToast.show(context, 'Invalid OTP', isSuccess: false);
          return;
        }

        final result = await userProvider.verifyOTP(
          mobile,
          otp,
          context: context,
        );

        final bool success = result['success'] == true;
        final String message = result['message'] ?? 'Something went wrong';

        if (success) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          //print(result['message']);
          setState(() {
            // _initializePromoterLevel();
          });
          // Sync user languages into LanguageProvider
          final user = userProvider.userObj;
          langProvider.setUserLanguages(user.selectedLanguages ?? []);
          log(user.selectedLanguages.toString());

          CustomToast.show(context, lang.loginSuccessfully, isSuccess: true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NavigationPage(),
            ),
          );
        } else {
          CustomToast.show(context, 'Failure: $message', isSuccess: false);
        }
      }
    } catch (e, stackTrace) {
      debugPrintStack(label: 'OTP Error', stackTrace: stackTrace);
      CustomToast.show(
        context,
        'An error occurred: ${e.toString()}',
        isSuccess: false,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _appendTvDigit(String digit) {
    final controller =
        otpSent && _editingOtp ? _otpController : _mobileController;
    final maxLength = otpSent && _editingOtp ? 6 : 10;
    final current = controller.text;
    if (current.length >= maxLength) return;

    controller.text = '$current$digit';
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    setState(() {});
  }

  void _removeTvDigit() {
    final controller =
        otpSent && _editingOtp ? _otpController : _mobileController;
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
        _showTvKeyboard();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _showTvKeyboard() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }
}

class _TvFocusFrame extends StatelessWidget {
  const _TvFocusFrame({
    required this.focusNode,
    required this.enabled,
    required this.child,
  });

  final FocusNode focusNode;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedScale(
          scale: focused ? 1.025 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: focused ? theme.primaryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

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
      _TvNumberPadKey(icon: Icons.backspace_outlined, onTap: onBackspace),
      _TvNumberPadKey(label: '0', onTap: () => onDigit('0')),
      _TvNumberPadKey(icon: Icons.check, onTap: onDone),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.25,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return FocusTraversalOrder(
          order: NumericFocusOrder(focusOrderStart + index),
          child: OttTvFocus(
            focusNode: focusNodes[index],
            onTap: key.onTap,
            borderRadius: 8,
            scale: 1.03,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryColor.withOpacity(0.55)),
              ),
              child: Center(
                child: key.icon == null
                    ? Text(
                        key.label!,
                        style: TextStyle(
                          color: theme.canvasColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : Icon(key.icon, color: theme.canvasColor, size: 22),
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
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
}
