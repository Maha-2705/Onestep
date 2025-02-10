import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:one_step/ParentScreens/DetailsPage.dart';
import 'package:one_step/config.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;

import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';


import 'package:one_step/Auth/SignInPage.dart';

import 'ProviderSignInPage.dart';


class SignUpPage extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}
class _RegistrationState extends State<SignUpPage> {
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
      VxToast.show(context, msg: "Name must be between 3 and 15 characters.");
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z]+\.[a-zA-Z]+").hasMatch(email)) {
      VxToast.show(context, msg: "Enter a valid email address.");
      return;
    }

    if (!RegExp(r"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$").hasMatch(password)) {
      VxToast.show(context, msg: "Password must be at least 8 characters, include an uppercase letter, a number, and a special character.");
      return;
    }

    if (!_termsAccepted) {
      VxToast.show(context, msg: "You must accept the terms and conditions.");
      return;
    }

    String role =  "Parent" ;

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

      if (jsonResponse['success']) { // Check 'success' field here
        VxToast.show(context, msg: jsonResponse['message'] ?? "Registered successfully!");
        Navigator.push(context, MaterialPageRoute(builder: (context) => SignInPage()));
      } else {
        VxToast.show(context, msg: jsonResponse['message'] ?? "Something went wrong. Please try again.");
      }
    } catch (e) {
      print('Error occurred: $e');
      VxToast.show(context, msg: "An error occurred. Please check your connection.");
    }
  }
  void Googlesignup() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        // Extract user details
        String name = googleUser.displayName ?? "Unknown";
        String email = googleUser.email;
        String photo = googleUser.photoUrl ?? "";

        // Define role type
        String roleType = "Parent"; // Change this if roleType is dynamic

        // Prepare request body
        Map<String, dynamic> requestBody = {
          "name": name,
          "email": email,
          "photo": photo,
          "roleType": roleType,
        };

        // Print request details
        print("Sending POST request to: https://1steptest.vercel.app/server/auth/google");
        print("Request Headers: { 'Content-Type': 'application/json' }");
        print("Request Body: ${jsonEncode(requestBody)}");

        // Send data to the server
        final response = await http.post(
          Uri.parse("https://1steptest.vercel.app/server/auth/google"),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        );

        // Print response details
        print("Response Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode == 200) {
          print("Google Sign-Up Success!");
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailsPage()),
          );
        } else {
          print("Error: ${response.statusCode} - ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Signup failed: ${response.body}")),
          );
        }
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
                      const Text(
                        'by creating a free account.',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily:'afacad',
                          color: Colors.grey,
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
                    fillColor: Colors.grey[200],
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
                    fillColor: Colors.grey[200],
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
                    fillColor: Colors.grey[200],
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
                      activeColor: Color(0xFF65467C),
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
                                color: Color(0xFF65467C),
                                fontWeight: FontWeight.bold,
                                  fontFamily:'afacad',
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Conditions.',
                              style: TextStyle(
                                color: Color(0xFF65467C),
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
                      backgroundColor: Color(0xFF65467C),
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
                      side: const BorderSide(color: Colors.grey),
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
                            color: Color(0xFF65467C),
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
