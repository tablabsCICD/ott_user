import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/provider/ThemeProvider.dart';

import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => getData());
  }

  Future<void> getData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();
    if (user != null && mounted) {
      await Provider.of<UserProvider>(context, listen: false)
          .getUserById(user.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    var selectedThemeData = themeProvider.getTheme;
    UserProvider userProvider = Provider.of<UserProvider>(context);

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
                              backgroundImage: userProvider
                                      .profileController.text.isNotEmpty
                                  ? NetworkImage(
                                      userProvider.profileController.text)
                                  : userProvider.userObj.profilePhoto != null
                                      ? userProvider
                                              .userObj.profilePhoto!.isNotEmpty
                                          ? NetworkImage(userProvider
                                              .userObj.profilePhoto!)
                                          : AssetImage(ImageConstant.profile)
                                      : AssetImage(ImageConstant.profile)),
                        ),
                        InkWell(
                          onTap: () => userProvider.pickImage(),
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
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedThemeData.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () async {
                        if (userProvider.profileController.text.isEmpty) {
                          userProvider.profileController.text =
                              userProvider.userObj.profilePhoto!;
                        }
                        if (userProvider.emailController.text.isEmpty) {
                          userProvider.emailController.text =
                              userProvider.userObj.emailId!;
                        }
                        if (userProvider.firstNameController.text.isEmpty) {
                          userProvider.firstNameController.text =
                              userProvider.userObj.firstName!;
                        }
                        if (userProvider.lastNameController.text.isEmpty) {
                          userProvider.lastNameController.text =
                              userProvider.userObj.lastName!;
                        }
                        var result = await userProvider.updateUser();
                        if (result['success'] == true) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);

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
}
