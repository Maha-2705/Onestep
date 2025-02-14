import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_step/AppColors.dart';
import 'package:one_step/ParentScreens/DetailsPage.dart';
import 'package:one_step/config.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'package:one_step/Auth/SignInPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ProviderSignInPage.dart';


class SignUpPage extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}
class _RegistrationState extends State<SignUpPage> {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final CookieJar cookieJar = CookieJar();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  bool _termsAccepted = false;
  bool _isParentSelected = true; // Default to 'Parent'

  void SignUp() async {
    String username = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || username.length < 3 || username.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Name must be between 3 and 15 characters.")),
      );
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z]+\.[a-zA-Z]+").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid email address.")),
      );
      return;
    }

    if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$").hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 8 characters, include an uppercase letter, a number, and a special character.")),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must accept the terms and conditions.")),
      );
      return;
    }

    String role = "Parent";

    var regBody = {
      "username": username,
      "email": email,
      "password": password,
      "roleType": role,
    };

    try {
      print('Sending request to server...');
      print('Request Body: $regBody');

      var response = await http
          .post(
        Uri.parse("https://1steptest.vercel.app/server/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(regBody),
      )
          .timeout(const Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? "Registered successfully!")),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderSignInPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? "Something went wrong. Please try again.")),
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please check your connection.")),
      );
    }
  }

  void Googlesignup() async {
    try {
      // Start Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // ✅ Force show account picker by signing out first
      await googleSignIn.signOut();

      // ✅ Now prompt for sign-in (this will show available accounts)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();


      if (googleUser == null) {
        print("Google Sign-In canceled.");
        return;
      }

      // Retrieve user details
      String name = googleUser.displayName ?? "Unknown";
      String email = googleUser.email;
      String photo = googleUser.photoUrl ?? "";
      String roleType = "Parent"; // Default role

      // Prepare data for backend
      Map<String, dynamic> requestBody = {
        "name": name,
        "email": email,
        "photo": photo,
        "roleType": roleType,
      };

      print("Google Sign-In Success: $requestBody");

      // Setup Dio for request and cookie handling
      final dio = Dio();
      final cookieJar = CookieJar();
      dio.interceptors.add(CookieManager(cookieJar));

      var response = await dio.post(
        "https://1steptest.vercel.app/server/auth/google",
        data: requestBody,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.data}");

      if (response.statusCode == 200) {
        var responseData = response.data;

        // ✅ Extract cookies
        List<Cookie> cookies = await cookieJar.loadForRequest(Uri.parse("https://1steptest.vercel.app/server/auth/google"));
        String? accessToken;
        String? refreshToken;

        for (var cookie in cookies) {
          if (cookie.name == "access_token") {
            accessToken = cookie.value;
          } else if (cookie.name == "refresh_token") {
            refreshToken = cookie.value;
          }
        }

        if (accessToken != null && refreshToken != null) {
          final storage = FlutterSecureStorage();
          await storage.write(key: 'access_token', value: accessToken);
          await storage.write(key: 'refresh_token', value: refreshToken);

          print("Extracted Access Token: $accessToken");
          print("Extracted Refresh Token: $refreshToken");
        }
        var Id = responseData['_id'];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('google_access_token', accessToken ?? "");
        prefs.setString('GoogleUserId', Id);

        if (responseData is Map<String, dynamic>) {
          print("User data stored successfully!");

          // Navigate to Details Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailsPage(userId: Id)),
          );
        } else {
          print("Unexpected response format: $responseData");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: Unexpected response format")),
          );
        }
      } else {
        print("Error: ${response.statusCode} - ${response.data}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup failed: ${response.data}")),
        );
      }
    } catch (error) {
      print("Google Sign-In Failed: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In Failed: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to ProviderSignInPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProviderSignInPage()),
                      );
                    },
                    child: Text(
                      "Are you Provider? Click here",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily:'afacad',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),


                const SizedBox(height: 30),
                // Illustration
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'Assets/Images/parent.png',
                        height: 120,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 28,
                          fontFamily:'afacad',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'by creating a free account.',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily:'afacad',
                          color: AppColors.greycolor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Full Name Field
                TextField(
                  style: TextStyle(
                    fontFamily:'afacad',
                  ),
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.textfieldcolor,
                  ),
                ),
                const SizedBox(height: 20),
                // Email Field
                TextField(
                  style: TextStyle(
                    fontFamily:'afacad',
                  ),
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Valid email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.textfieldcolor,
                  ),
                ),
                const SizedBox(height: 20),
                // Password Field
                TextField(
                  style: TextStyle(
                    fontFamily:'afacad',
                  ),
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Strong Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.textfieldcolor,
                  ),
                ),
                const SizedBox(height: 20),
                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryColor,
                    ),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'By checking the box you agree to our ',
                          style: TextStyle(
                            fontFamily:'afacad',
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                  fontFamily:'afacad',
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Conditions.',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                  fontFamily:'afacad',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: SignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                          fontFamily:'afacad',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed:  Googlesignup,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.greycolor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('Assets/Images/google_icon.png', height: 24), // Larger Google Icon
                        const SizedBox(width: 10),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Already a member? Log In
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                  style: TextStyle(
                  fontFamily:'afacad',
                ),),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignInPage()),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                              fontFamily:'afacad',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
