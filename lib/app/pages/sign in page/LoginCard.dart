import 'dart:developer';

import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();

  bool otpSent = false;
  bool isLoading = false;

  String selectedCode = '+91';
  final List<String> countryCodes = ['+91', '+1', '+44', '+61', '+971'];

  @override
  void initState() {
    //_initializePromoterLevel();
    super.initState();
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
      body: Center(
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
                            IntlPhoneField(
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
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: theme.cardColor,

                                hintText: lang.enterMobileNumber,
                                hintStyle: const TextStyle(fontSize: 14),
                                // Border properties
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                      color: Colors
                                          .grey[400]!), // Default border color
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
                                      width: 2), // Border color when focused
                                ),
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
                            const SizedBox(height: 10),

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
                              PinCodeTextField(
                                cursorColor: theme.primaryColor,
                                appContext: context,
                                length: 6,
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                animationType: AnimationType.fade,
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.box,
                                  borderRadius: BorderRadius.circular(8),
                                  fieldHeight: 50,
                                  fieldWidth: ResponsiveWidget.isMobile(context)
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
                              const SizedBox(height: 20),
                            ],

                            /// Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _handleLoginOrOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                                        otpSent ? lang.verifyOtp : lang.sendOtp,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                SizedBox(
                  height: ResponsiveWidget.isMobile(context) ? 150 : 60,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Dropdown styled like CustomTextField

  // OTP send/verify logic
  void _handleLoginOrOtp() async {
    if (!_formKey.currentState!.validate() || _mobileController.text.isEmpty)
      return;
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

        final result = await userProvider.verifyOTP(mobile, otp);

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
}
