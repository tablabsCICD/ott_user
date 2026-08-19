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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getData();
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_sharp, color: Colors.white),
          onPressed: () async {
            final shouldPop = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  title: const Text("Discard Changes?"),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      "Are you sure you want to go back?",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: selectedThemeData.canvasColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        userProvider.profileController.clear();
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        "Discard",
                        style: TextStyle(color: selectedThemeData.primaryColor),
                      ),
                    ),
                  ],
                );
              },
            );
            if (shouldPop ?? false) {
              Navigator.of(context).pop();
            }
          },
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
                      label: 'Enter First Name',
                      isName: true,
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
                      label: 'Enter Last Name',
                      isName: true,
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
                      label: 'Email',
                      isEmail: true,
                      isValidator: true,
                      hintText:
                          userProvider.userObj.emailId ?? 'Enter valid email',
                      textInputType: TextInputType.emailAddress,
                    ),
                    CustomTextField(
                      controller: userProvider.dobController,
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
                          : () async {
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
                                final prefs =
                                    await SharedPreferences.getInstance();
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
                            },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedThemeData.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: userProvider.isUploading
                            ? null
                            : () async {
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
                                  final prefs =
                                      await SharedPreferences.getInstance();
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
                              },
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

  Future<void> _selectDate(UserProvider userProvider) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDobDate(userProvider.dobController.text, now),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (pickedDate != null) {
      userProvider.setDate(pickedDate);
    }
  }

  DateTime _initialDobDate(String value, DateTime fallback) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null || parsed.isAfter(fallback)) return fallback;
    return parsed;
  }
}
