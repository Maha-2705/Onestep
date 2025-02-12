import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:one_step/Auth/ResetPassword.dart';
import 'package:one_step/ParentScreens/ParentDashBoard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../ParentScreens/DetailsPage.dart';
import '../ProviderScreens/ProviderDetailsPage.dart';
import 'package:one_step/Auth/SignUpPage.dart';

import 'ProviderSignInPage.dart';



class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final CookieJar cookieJar = CookieJar();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isChecked = false;
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

    if (email.isEmpty || !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
      VxToast.show(context, msg: "Please enter a valid email address.");
      return;
    }

    if (password.isEmpty || password.length < 6) {
      VxToast.show(context, msg: "Password must be at least 6 characters.");
      return;
    }

    var loginBody = {"email": email, "password": password};
    final dio = Dio();
    final cookieJar = CookieJar();
    dio.interceptors.add(CookieManager(cookieJar));

    try {
      var response = await dio.post(
        "https://1steptest.vercel.app/server/auth/signin",
        data: loginBody,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.data}');

      if (response.statusCode == 200) {
        var jsonResponse = response.data;

        // ✅ Correct way to extract cookies
        List<Cookie> cookies = await cookieJar.loadForRequest(Uri.parse("https://1steptest.vercel.app/server/auth/signin"));
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

        var Id = jsonResponse['_id'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('Id', Id);
        prefs.setString('access_token', accessToken ?? "");

        print("Id: $Id");
        print("access_token: $accessToken");

        var role = jsonResponse['role'];
        if (role != null && role['role'] == 'Parent') {
          VxToast.show(context, msg: jsonResponse['message'] ?? "Login successful!");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DetailsPage(userId: Id)),
          );
        } else {
          VxToast.show(context, msg: "You are not a Parent user.");
        }
      } else {
        print('Error: Server returned status code ${response.statusCode}');
        VxToast.show(context, msg: "Server error: ${response.statusCode}");
      }
    } catch (e) {
      print('Error occurred: $e');
      VxToast.show(context, msg: "An error occurred. Please check your connection.");
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
        prefs.setString('GoogleUserId', Id);

        prefs.setString('google_access_token', accessToken ?? "");
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
                // Instruction Text
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
                        'Assets/Images/parent.png',
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
                          ),),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigate to Forgot Password Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
                        );
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
                    onPressed: SignIn,

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

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: Googlesignup,
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
                // Register Now Row
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('New user? ',
                        style: TextStyle(
                          fontFamily:'afacad',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to SignUpPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpPage()),
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