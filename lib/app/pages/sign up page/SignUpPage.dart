// import 'package:flutter/material.dart';
// import 'package:ott/app/pages/sign%20in%20page/SignInPage.dart';
// import 'package:ott/app/pages/sign%20up%20page/SelectLanguage.dart';
// import 'package:ott/app/provider/ThemeProvider.dart';
// import 'package:ott/app/widgets/customtextfield.dart';
// import 'package:ott/device/utils/ResponsiveWidget.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import '../../provider/userProvider.dart';
// import '../../widgets/show_toast.dart';

// class SignUpPage extends StatefulWidget {
//   @override
//   _SignUpPageState createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   @override
//   Widget build(BuildContext context) {
//     var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
//     var userProvider = Provider.of<UserProvider>(context, listen: true);
//     var selectedThemeData = themeProvider.getTheme;
//     bool isDark = selectedThemeData.brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: selectedThemeData.scaffoldBackgroundColor,
//       appBar: AppBar(
//         centerTitle: true,
//         title: const Text("Sign Up"),
//         leading: InkWell(
//             onTap: () {
//               Navigator.pop(context);
//             },
//             child: Icon(Icons.arrow_back_ios_new)),
//         backgroundColor: selectedThemeData.primaryColor,
//         actions: [
//           IconButton(
//             icon: Icon(
//               isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
//               color: selectedThemeData.canvasColor,
//             ),
//             onPressed: themeProvider.toggleTheme,
//           ),
//         ],
//       ),
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return Center(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.only(
//                 left: 20,
//                 right: 20,
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//               ),
//               child: SizedBox(
//                 width:
//                     ResponsiveWidget.isMobile(context) ? double.infinity : 400,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 15),
//                     CustomTextField(
//                       controller: userProvider.firstNameController,
//                       hintText: "Enter your first name",
//                       label: "First Name",
//                       textInputType: TextInputType.name,
//                       capitalization: TextCapitalization.words,
//                       isValidator: true,
//                     ),
//                     CustomTextField(
//                       controller: userProvider.lastNameController,
//                       hintText: "Enter your last name",
//                       label: "Last Name",
//                       textInputType: TextInputType.name,
//                       capitalization: TextCapitalization.words,
//                       isValidator: true,
//                     ),
//                     CustomTextField(
//                       controller: userProvider.emailController,
//                       hintText: "Enter your email",
//                       label: "Email",
//                       textInputType: TextInputType.emailAddress,
//                       isEmail: true,
//                       capitalization: TextCapitalization.none,
//                       isValidator: true,
//                     ),
//                     CustomTextField(
//                       controller: userProvider.mobileController,
//                       hintText: "Enter your Contact Number",
//                       label: "Contact Number",
//                       textInputType: TextInputType.number,
//                       isEmail: true,
//                       capitalization: TextCapitalization.none,
//                       isValidator: true,
//                     ),
//                     CustomTextField(
//                       controller: userProvider.passwordController,
//                       hintText: "Enter your password",
//                       label: "Password",
//                       textInputType: TextInputType.text,
//                       isPassword: true,
//                       isValidator: true,
//                     ),
//                     CustomTextField(
//                       controller: userProvider.confirmPasswordController,
//                       hintText: "Confirm your password",
//                       label: "Confirm Password",
//                       textInputType: TextInputType.text,
//                       isPassword: true,
//                       isValidator: true,
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         _buildGenderButton(
//                             "Male", selectedThemeData, userProvider),
//                         _buildGenderButton(
//                             "Female", selectedThemeData, userProvider),
//                         _buildGenderButton(
//                             "Other", selectedThemeData, userProvider),
//                       ],
//                     ),
//                     const SizedBox(height: 25),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: selectedThemeData.primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                       ),
//                       onPressed: () {
//                         _handleSignUp(userProvider);
//                       },
//                       child: const Center(
//                         child: Text(
//                           "Sign Up",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text("Already have an account?",
//                             style: TextStyle(
//                                 color: selectedThemeData.canvasColor,
//                                 fontSize: 14)),
//                         TextButton(
//                           onPressed: _navigateToSignIn,
//                           child: Text(
//                             "Sign In",
//                             style: TextStyle(
//                               color: selectedThemeData.primaryColor,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(
//                       height: 50,
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildGenderButton(
//       String gender, ThemeData selectedThemeData, UserProvider userProvider) {
//     return GestureDetector(
//       onTap: () => setState(() => userProvider.selectedGender = gender),
//       child: Container(
//         height: 35,
//         width: 90,
//         decoration: BoxDecoration(
//           color: selectedThemeData.cardColor,
//           border: Border.all(
//             width: userProvider.selectedGender == gender ? 2 : 0.5,
//             color: userProvider.selectedGender == gender
//                 ? selectedThemeData.primaryColor
//                 : selectedThemeData.canvasColor,
//           ),
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Center(
//           child: Text(
//             gender,
//             style: TextStyle(
//               color: userProvider.selectedGender == gender
//                   ? selectedThemeData.primaryColor
//                   : selectedThemeData.canvasColor,
//               fontWeight: userProvider.selectedGender == gender
//                   ? FontWeight.bold
//                   : FontWeight.normal,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _handleSignUp(UserProvider provider) async {
//     final email = provider.emailController.text.trim();
//     final mobile = provider.mobileController.text.trim();
//     final password = provider.passwordController.text.trim();
//     final confirmPassword = provider.confirmPasswordController.text.trim();
//     final name = provider.firstNameController.text.trim() +
//         provider.lastNameController.text.trim();

//     if (email.isEmpty ||
//         password.isEmpty ||
//         confirmPassword.isEmpty ||
//         name.isEmpty ||
//         provider.selectedGender == null) {
//       CustomToast.show(context, 'Please fill out all fields', isSuccess: false);

//       return;
//     }

//     if (password != confirmPassword) {
//       CustomToast.show(context, 'Passwords do not match', isSuccess: false);

//       return;
//     }
//     Navigator.push(
//         context, MaterialPageRoute(builder: (context) => SelectLanguagePage()));
//     await Future.delayed(Duration(milliseconds: 500));
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isLoggedIn', false);
//     await prefs.setString('userEmail', email);
//     await prefs.setString('Name', name);
//     await prefs.setString('Mobile', mobile);
//     await prefs.setString('gender', provider.selectedGender!);
//   }

//   void _navigateToSignIn() => Navigator.pushReplacement(
//       context, MaterialPageRoute(builder: (context) => SignInPage()));
// }
