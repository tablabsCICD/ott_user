import 'package:flutter/material.dart';
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
  }

  /* void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      Provider.of<UserProvider>(context, listen: false).updateUser(
        name: _nameController.text,
        email: _emailController.text,
        mobileNumber: _mobileController.text,
        image: _imageController.text,
        balance:
            Provider.of<UserProvider>(context, listen: false).walletBalance,
        referredBy:
            Provider.of<UserProvider>(context, listen: false).referredBy,
      );
      Navigator.pop(context);
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: true);
    var themeProvider = Provider.of<ThemeProvider>(context);
    var selectedThemeData = themeProvider.getTheme;
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: selectedThemeData.primaryColor,
        title: Text(lang.editProfile),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: ResponsiveWidget.isMobile(context) ? double.infinity : 400,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await userProvider.pickImage();
                    },
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        children: [
                          Hero(
                            tag: "profile",
                            child: CircleAvatar(
                              radius: 85,
                              backgroundImage:
                                  userProvider.profileController.text.isNotEmpty
                                      ? NetworkImage(
                                          userProvider.profileController.text)
                                      : null,
                              backgroundColor: Colors.grey[300],
                              child: userProvider.profileController.text.isEmpty
                                  ? Icon(Icons.add_a_photo,
                                      color: Colors.grey[600], size: 50)
                                  : null,
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: InkWell(
                              onTap: () async {
                                await userProvider.pickImage();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[
                                      600], // Background color of the icon
                                ),
                                padding: EdgeInsets.all(
                                    8.0), // Adjust padding as needed
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white, // Color of the icon
                                  size: 20, // Adjust the size as needed
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  CustomTextField(
                    controller: userProvider.firstNameController,
                    isName: true,
                    hintText: lang.enterFirstName,
                    label: lang.firstName,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.lastNameController,
                    isName: true,
                    hintText: lang.enterLastName,
                    label: lang.lastName,
                    isValidator: true,
                    textInputType: TextInputType.name,
                    //decoration: const InputDecoration(labelText: 'Name'),
                    //validator: (value) =>
                    //  value!.isEmpty ? 'Enter a valid name' : null,
                  ),
                  CustomTextField(
                    controller: userProvider.emailController,
                    isEmail: true,
                    isValidator: true,
                    hintText: lang.enterEmail,
                    label: lang.email,
                    textInputType: TextInputType.emailAddress,
                    // decoration: const InputDecoration(labelText: 'Email'),
                    // validator: (value) =>
                    //     value!.contains('@') ? null : 'Enter a valid email',
                  ),
                  // CustomTextField(
                  //   controller: userProvider.mobileController,
                  //   isEmail: true,
                  //   isValidator: true,
                  //   hintText: lang.enterMobileNumber,
                  //   label: lang.mobileNumber,
                  //   textInputType: TextInputType.number,
                  // ),
                  // CustomTextField(
                  //   controller: _imageController,
                  //   decoration:
                  //       const InputDecoration(labelText: 'Profile Image URL'),
                  // ),
                  const SizedBox(height: 20),
                  // ElevatedButton(
                  //   onPressed: _saveProfile,
                  //   child: const Text('Save Changes'),
                  // ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: ResponsiveWidget.isMobile(context)
                          ? double.infinity
                          : 400,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedThemeData.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () async {
                          var result = await userProvider.updateUser();
                          if (result['success'] == true) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('isLoggedIn', true);

                            CustomToast.show(
                                context, lang.profileUpdatedSuccessfully,
                                isSuccess: true);

                            Navigator.of(context).pop();
                          } else {
                            CustomToast.show(
                                context, 'Failure: ${result['message']}',
                                isSuccess: false);
                          }
                        },
                        child: Center(
                          child: Text(
                            lang.save,
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
                  SizedBox(
                    height: 30,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
