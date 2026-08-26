import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/customtextfield.dart';
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
  final _firstNameFocusNode = FocusNode(debugLabel: 'edit-first-name');
  final _lastNameFocusNode = FocusNode(debugLabel: 'edit-last-name');
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
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
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
                      controller: userProvider.firstNameController,
                      focusNode: _firstNameFocusNode,
                      autofocus: ResponsiveWidget.isTabletOrTv(context),
                      label: 'Enter First Name',
                      isName: true,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                      hintText: userProvider.userObj.firstName != null
                          ? userProvider.userObj.firstName!.isNotEmpty
                              ? userProvider.userObj.firstName!
                              : 'Enter a valid name'
                          : 'Enter a valid name',
                      isValidator: true,
                      textInputType: TextInputType.name,
                    ),
                    CustomTextField(
                      controller: userProvider.lastNameController,
                      focusNode: _lastNameFocusNode,
                      label: 'Enter Last Name',
                      isName: true,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                      hintText: userProvider.userObj.lastName != null
                          ? userProvider.userObj.lastName!.isNotEmpty
                              ? userProvider.userObj.lastName!
                              : 'Enter a valid name'
                          : 'Enter a valid name',
                      isValidator: true,
                      textInputType: TextInputType.name,
                    ),
                    CustomTextField(
                      controller: userProvider.emailController,
                      focusNode: _emailFocusNode,
                      label: 'Email',
                      isEmail: true,
                      isValidator: true,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _dobFocusNode.requestFocus();
                        _selectDate(userProvider);
                      },
                      hintText:
                          userProvider.userObj.emailId ?? 'Enter valid email',
                      textInputType: TextInputType.emailAddress,
                    ),
                    CustomTextField(
                      controller: userProvider.dobController,
                      focusNode: _dobFocusNode,
                      label: 'Birth Date',
                      isValidator: true,
                      readOnly: true,
                      suffixIcon: Icons.calendar_today_outlined,
                      hintText: userProvider.userObj.dob != null
                          ? userProvider.userObj.dob!.isNotEmpty
                              ? userProvider.userObj.dob!
                              : 'Enter birth date'
                          : 'Enter birth date',
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
    if (userProvider.firstNameController.text.isEmpty) {
      userProvider.firstNameController.text =
          userProvider.userObj.firstName ?? '';
    }
    if (userProvider.lastNameController.text.isEmpty) {
      userProvider.lastNameController.text =
          userProvider.userObj.lastName ?? '';
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
    final now = DateTime.now();
    final initialDate = _initialDobDate(userProvider.dobController.text, now);

    if (ResponsiveWidget.isTabletOrTv(context)) {
      final pickedDate = await _showTvDatePicker(context, initialDate);
      if (pickedDate != null) {
        userProvider.setDate(pickedDate);
      }
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      userProvider.setDate(pickedDate);
    }
  }

  Future<DateTime?> _showTvDatePicker(
    BuildContext pageContext,
    DateTime initialDate,
  ) async {
    final theme = Theme.of(pageContext);
    DateTime tempDate = initialDate;

    return showDialog<DateTime>(
      context: pageContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void updateDate(int year, int month, int day) {
              final lastDay = DateTime(year, month + 1, 0).day;
              final safeDay = day.clamp(1, lastDay);
              final newDate = DateTime(year, month, safeDay);
              if (newDate.isAfter(DateTime.now())) return;
              setDialogState(() {
                tempDate = newDate;
              });
            }

            return Dialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Birth Date',
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDateSpinner(
                          label: 'Day',
                          value: tempDate.day.toString().padLeft(2, '0'),
                          onDecrement: () => updateDate(
                              tempDate.year, tempDate.month, tempDate.day - 1),
                          onIncrement: () => updateDate(
                              tempDate.year, tempDate.month, tempDate.day + 1),
                          theme: theme,
                        ),
                        const SizedBox(width: 14),
                        _buildDateSpinner(
                          label: 'Month',
                          value: tempDate.month.toString().padLeft(2, '0'),
                          onDecrement: () => updateDate(
                              tempDate.year, tempDate.month - 1, tempDate.day),
                          onIncrement: () => updateDate(
                              tempDate.year, tempDate.month + 1, tempDate.day),
                          theme: theme,
                        ),
                        const SizedBox(width: 14),
                        _buildDateSpinner(
                          label: 'Year',
                          value: tempDate.year.toString(),
                          onDecrement: () => updateDate(
                              tempDate.year - 1, tempDate.month, tempDate.day),
                          onIncrement: () => updateDate(
                              tempDate.year + 1, tempDate.month, tempDate.day),
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OttTvFocus(
                          borderRadius: 8,
                          onTap: () => Navigator.of(dialogContext).pop(null),
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(null),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: theme.canvasColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        OttTvFocus(
                          autofocus: true,
                          borderRadius: 8,
                          onTap: () =>
                              Navigator.of(dialogContext).pop(tempDate),
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(tempDate),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('OK'),
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
      },
    );
  }

  Widget _buildDateSpinner({
    required String label,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.canvasColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        OttTvFocus(
          borderRadius: 8,
          onTap: onIncrement,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_up,
                color: theme.canvasColor, size: 24),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.canvasColor.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        OttTvFocus(
          borderRadius: 8,
          onTap: onDecrement,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.keyboard_arrow_down,
                color: theme.canvasColor, size: 24),
          ),
        ),
      ],
    );
  }

  DateTime _initialDobDate(String value, DateTime fallback) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.isAfter(fallback)) return fallback;
    return parsed;
  }
}
