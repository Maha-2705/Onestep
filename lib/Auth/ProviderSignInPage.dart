import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:one_step/ParentScreens/ParentDashBoard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;

import '../ParentScreens/DetailsPage.dart';
import '../ProviderScreens/ProviderDetailsPage.dart';
import 'package:one_step/Auth/SignInPage.dart';

import 'package:one_step/Auth/ProviderSignUpPage.dart';



class ProviderSignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<ProviderSignInPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isNotValidate = false;
  bool _isChecked = false;
  bool _isParentSelected = true; // Default to 'Parent'
  late SharedPreferences prefs;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async{
    prefs = await SharedPreferences.getInstance();
  }
  void SignIn() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Validate email


    var loginBody = {
      "email": email,
      "password": password,
    };

    try {
      print('Sending login request to server...');
      print('Request Body: $loginBody');

      var response = await http
          .post(
        Uri.parse("https://1steptest.vercel.app/server/auth/signin"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(loginBody),
      )
          .timeout(const Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      var jsonResponse = jsonDecode(response.body);
      var myToken = jsonResponse['token'];
      prefs.setString('token', myToken);

      if (jsonResponse['success']) { // Check 'success' field here
        VxToast.show(context, msg: jsonResponse['message'] ?? "Login successful!");
        Navigator.push(context, MaterialPageRoute(builder: (context) => ParentDashBoard())); // Redirect to home page
      } else {
        VxToast.show(context, msg: jsonResponse['message'] ?? "Invalid credentials. Please try again.");
      }
    } catch (e) {
      print('Error occurred: $e');
      VxToast.show(context, msg: "An error occurred. Please check your connection.");
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
                // Instruction Text
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to ProviderSignInPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignInPage()),
                      );
                    },
                    child: Text(
                      "Are you Parent? Click here",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                          fontFamily:'afacad',
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
                        'Assets/Images/therapist.png',
                        height: 120,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                            fontFamily:'afacad',
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Signin to access your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                            fontFamily:'afacad',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Email TextField
                TextField(
                  style: TextStyle(
                    fontFamily:'afacad',
                  ),
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
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
                // Password TextField
                TextField(
                  style: TextStyle(
                    fontFamily:'afacad',
                  ),
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 10),
                // Remember Me and Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _isChecked,
                          onChanged: (value) {
                            setState(() {
                              _isChecked = value!;
                            });
                          },
                          activeColor: Color(0xFF65467C), // Set the checkbox color to blue
                        ),


                        const Text('Remember me',
                          style: TextStyle(
                          fontFamily:'afacad',
                        )),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to Forgot Password Screen
                      },
                      child: const Text(
                        'Forget password ?',
                        style: TextStyle(
                          color: Color(0xFF65467C),
                          fontWeight: FontWeight.w500,
                            fontFamily:'afacad',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Sign In logic here
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProviderDetailsPage()),
                      );

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF65467C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                          fontFamily:'afacad',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Register Now Row
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New user? ',
                  style: TextStyle(
                  fontFamily:'afacad',
                ),),
                      GestureDetector(
                        onTap: () {
                          // Navigate to SignUpPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProviderSignUpPage()),
                          );
                        },
                        child: const Text(
                          'Register',
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