// import 'package:flutter/material.dart';
// import 'package:ott/app/pages/NavigationPage.dart';
// import 'package:ott/app/pages/sign%20up%20page/SignUpPage.dart';
// import 'package:ott/app/provider/ThemeProvider.dart';
// import 'package:ott/app/provider/userProvider.dart';
// import 'package:ott/app/widgets/customtextfield.dart';
// import 'package:ott/device/utils/ResponsiveWidget.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../core/constant/image_constant.dart';
// import '../../widgets/show_toast.dart';

// class SignInPage extends StatefulWidget {
//   @override
//   _SignInPageState createState() => _SignInPageState();
// }

// class _SignInPageState extends State<SignInPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     var themeProvider = Provider.of<ThemeProvider>(context, listen: true);
//     var selectedThemeData = themeProvider.getTheme;
//     bool isDark = selectedThemeData.brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: selectedThemeData.scaffoldBackgroundColor,
//       appBar: AppBar(
//         backgroundColor: selectedThemeData.scaffoldBackgroundColor,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(
//               isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
//               color: selectedThemeData.canvasColor,
//             ),
//             onPressed: () {
//               themeProvider.toggleTheme();
//             },
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//             width: ResponsiveWidget.isMobile(context) ? double.infinity : 400,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(
//                   height: ResponsiveWidget.isMobile(context) ? 50 : 20,
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       child: Image.asset(
//                         ImageConstant.logo,
//                         width: 200,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(
//                   height: 20,
//                 ),
//                 Text(
//                   "Sign In",
//                   style: TextStyle(
//                     color: selectedThemeData.canvasColor,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 CustomTextField(
//                   controller: _emailController,
//                   hintText: "Enter your email",
//                   label: "Email",
//                   textInputType: TextInputType.emailAddress,
//                   isEmail: true,
//                   capitalization: TextCapitalization.none,
//                   isValidator: true,
//                 ),
//                 CustomTextField(
//                   controller: _passwordController,
//                   hintText: "Enter your password",
//                   label: "Password",
//                   textInputType: TextInputType.text,
//                   isPassword: true,
//                   isValidator: true,
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: selectedThemeData.primaryColor,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                   ),
//                   onPressed: _isLoading ? null : _handleLogin,
//                   child: _isLoading
//                       ? CircularProgressIndicator(
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Colors.white),
//                         )
//                       : const Center(
//                           child: Text(
//                             "Sign In",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                 ),
//                 const SizedBox(height: 15),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Don't have an account?",
//                       style: TextStyle(
//                           color: selectedThemeData.canvasColor, fontSize: 14),
//                     ),
//                     TextButton(
//                       onPressed: _navigateToSignUp,
//                       child: Text(
//                         "Sign Up",
//                         style: TextStyle(
//                           color: selectedThemeData.primaryColor,
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _handleLogin() async {
//     final email = _emailController.text.trim();
//     final password = _passwordController.text.trim();
//     if (email.isEmpty || password.isEmpty) {
//       CustomToast.show(context, 'Please fill out all fields', isSuccess: false);
//       return;
//     }
//     setState(() {
//       _isLoading = true;
//     });
//     var result = await Provider.of<UserProvider>(context, listen: false)
//         .login(email, password);
//     if (result['success'] == true) {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool('isLoggedIn', true);
//       CustomToast.show(context, 'Welcome back, $email!', isSuccess: true);
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => NavigationPage(),
//         ),
//       );
//       setState(() {
//         _isLoading = false;
//       });
//     } else {
//       print('Failure: ${result['message']}');
//       CustomToast.show(context, result['message'].toString(), isSuccess: false);
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _navigateToSignUp() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SignUpPage(),
//       ),
//     );
//   }
// }
