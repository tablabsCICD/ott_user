import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/month_year_picker_dialog.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../provider/userProvider.dart';
import '../../../widgets/show_toast.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameFocusNode = FocusNode(debugLabel: 'edit-name');
  final _emailFocusNode = FocusNode(debugLabel: 'edit-email');
  final _dobFocusNode = FocusNode(debugLabel: 'edit-dob');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getData();
    });
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _dobFocusNode.dispose();
    super.dispose();
  }

  Future<void> getData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.hydrateFromCache();
    if (!mounted) return;
    if (user != null) {
      await userProvider.getUserById(user.id!);
    }
  }

  Future<void> _handleBackPress(
    BuildContext context,
    UserProvider userProvider,
    ThemeData selectedThemeData,
  ) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: selectedThemeData.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Discard Changes?",
                  style: TextStyle(
                    color: selectedThemeData.canvasColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Are you sure you want to go back?",
                  style: TextStyle(
                    color: selectedThemeData.canvasColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OttTvFocus(
                      borderRadius: 8,
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: selectedThemeData.canvasColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OttTvFocus(
                      borderRadius: 8,
                      onTap: () {
                        userProvider.profileController.clear();
                        Navigator.of(dialogContext).pop(true);
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedThemeData.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          userProvider.profileController.clear();
                          Navigator.of(dialogContext).pop(true);
                        },
                        child: const Text(
                          "Discard",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if ((shouldPop ?? false) && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    var selectedThemeData = themeProvider.getTheme;
    UserProvider userProvider = Provider.of<UserProvider>(context);
    final cachedPhoto = userProvider.userObj.profilePhoto ?? '';
    final ImageProvider avatarImage =
        userProvider.profileController.text.isNotEmpty
            ? NetworkImage(userProvider.profileController.text)
            : cachedPhoto.isNotEmpty
                ? NetworkImage(cachedPhoto)
                : AssetImage(ImageConstant.profile);

    return Scaffold(
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: selectedThemeData.primaryColor,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        leading: OttTvFocus(
          borderRadius: 20,
          onTap: () => _handleBackPress(context, userProvider, selectedThemeData),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_sharp, color: Colors.white),
            onPressed: () => _handleBackPress(context, userProvider, selectedThemeData),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                width:
                    ResponsiveWidget.isMobile(context) ? double.infinity : 400,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(
                          tag: 'profile',
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: selectedThemeData.cardColor,
                            backgroundImage: avatarImage,
                          ),
                        ),
                        OttTvFocus(
                          borderRadius: 25,
                          scale: 1.1,
                          semanticLabel: 'Change profile picture',
                          onTap: userProvider.isUploading
                              ? null
                              : () => userProvider.pickImage(),
                          child: InkWell(
                            onTap: userProvider.isUploading
                                ? null
                                : () => userProvider.pickImage(),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selectedThemeData.cardColor,
                                border: Border.all(
                                  color: selectedThemeData.canvasColor,
                                  width: 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.edit,
                                color: selectedThemeData.canvasColor,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (userProvider.isUploading)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: userProvider.nameController,
                      focusNode: _nameFocusNode,
                      autofocus: ResponsiveWidget.isTabletOrTv(context),
                      label: 'Name',
                      hintText: (() {
                        final first =
                            (userProvider.userObj.firstName ?? '').trim();
                        final last =
                            (userProvider.userObj.lastName ?? '').trim();
                        final fullName = '$first $last'.trim();
                        return fullName.isNotEmpty
                            ? fullName
                            : 'Enter your name';
                      })(),
                      isValidator: false,
                      textInputType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                    ),
                    CustomTextField(
                      controller: userProvider.emailController,
                      focusNode: _emailFocusNode,
                      label: 'Email (Optional)',
                      isEmail: false,
                      isValidator: false,
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final emailRegex =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(val.trim())) {
                            return 'Enter valid email';
                          }
                        }
                        return null;
                      },
                      hintText:
                          userProvider.userObj.emailId ?? 'Enter valid email',
                      textInputType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _dobFocusNode.requestFocus();
                        _selectDate(userProvider);
                      },
                    ),
                    CustomTextField(
                      controller: userProvider.dobController,
                      focusNode: _dobFocusNode,
                      label: 'Birth Date (Month & Year)',
                      isValidator: false,
                      readOnly: true,
                      suffixIcon: Icons.calendar_today_outlined,
                      hintText: userProvider.userObj.dob != null
                          ? userProvider.userObj.dob!.isNotEmpty
                              ? userProvider.userObj.dob!
                              : 'Select birth month and year'
                          : 'Select birth month and year',
                      textInputType: TextInputType.datetime,
                      onTap: () => _selectDate(userProvider),
                    ),
                    const SizedBox(height: 30),
                    OttTvFocus(
                      borderRadius: 6,
                      scale: 1.02,
                      semanticLabel: "Save profile",
                      onTap: userProvider.isUploading
                          ? null
                          : () => _saveProfile(userProvider),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedThemeData.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: userProvider.isUploading
                            ? null
                            : () => _saveProfile(userProvider),
                        child: const Center(
                          child: Text(
                            "Save",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile(UserProvider userProvider) async {
    if (userProvider.profileController.text.isEmpty) {
      userProvider.profileController.text =
          userProvider.userObj.profilePhoto ?? '';
    }
    if (userProvider.emailController.text.isEmpty) {
      userProvider.emailController.text =
          userProvider.userObj.emailId ?? '';
    }
    final fullName = userProvider.nameController.text.trim();
    if (fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      userProvider.firstNameController.text = parts.first;
      userProvider.lastNameController.text =
          parts.length > 1 ? parts.sublist(1).join(' ') : '';
    } else {
      userProvider.firstNameController.text = '';
      userProvider.lastNameController.text = '';
    }
    if (userProvider.mobileController.text.isEmpty) {
      userProvider.mobileController.text =
          userProvider.userObj.mobileNumber ?? '';
    }
    if (userProvider.dobController.text.isEmpty) {
      userProvider.dobController.text =
          userProvider.userObj.dob ?? '';
    }
    if (!_formKey.currentState!.validate()) return;
    var result = await userProvider.updateUser();
    if (!mounted) return;
    if (result['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      if (!mounted) return;

      CustomToast.show(
        context,
        "Profile updated successfully!",
        isSuccess: true,
      );
      Navigator.of(context).pop();
    } else {
      CustomToast.show(
        context,
        'Failure: ${result['message']}',
        isSuccess: false,
      );
    }
  }

  Future<void> _selectDate(UserProvider userProvider) async {
    final result = await showBirthMonthYearPicker(
      context: context,
      currentValue: userProvider.dobController.text,
    );

    if (result != null) {
      userProvider.setBirthMonthAndYear(
        result['month'] as String,
        result['year'] as int,
      );
    }
  }
}
