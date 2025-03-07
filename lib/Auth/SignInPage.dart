import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:one_step/Auth/ResetPassword.dart';
import 'package:one_step/ParentScreens/ParentDashBoard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _isObscure = true; // Add this variable to track password visibility


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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid email address.")),
      );
      return;
    }

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password must be at least 6 characters.")),
      );
      return;
    }

    var loginBody = {"email": email, "password": password};
    dio.interceptors.add(CookieManager(cookieJar));

    try {
      var response = await dio.post(
        "https://1steptest.vercel.app/server/auth/signin",
        data: loginBody,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      print("Login Response: ${response.data}");
      print("Login Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        var jsonResponse = response.data;
        String? loginUserId = jsonResponse['_id'];

        List<Cookie> cookies = await cookieJar.loadForRequest(Uri.parse("https://1steptest.vercel.app/server/auth/signin"));
        String? accessToken;

        for (var cookie in cookies) {
          if (cookie.name == "access_token") {
            accessToken = cookie.value;
          }
        }

        if (accessToken != null) {
          await storage.write(key: 'access_token', value: accessToken);
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('ID', loginUserId!);
        prefs.setString('access_token', accessToken ?? "");

        // ✅ Call Parent API
        var parentResponse = await dio.get(
          "https://1steptest.vercel.app/server/parent/getParent/$loginUserId",
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Cookie": "access_token=$accessToken",
            },
          ),
        );

        print("Parent API Response: ${parentResponse.data}");
        print("Parent API Status Code: ${parentResponse.statusCode}");

        if (parentResponse.statusCode == 200 && parentResponse.data != null) {
          var parentData = parentResponse.data;

          // ❌ If "status": false, move to DetailsPage
          if (parentData.containsKey("status") && parentData["status"] == false) {


            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DetailsPage(userId: loginUserId)),
            );
            return;
          }

          // ✅ If parentDetails exist, move to ParentDashBoard
          if (parentData.containsKey("parentDetails")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Login successful! Redirecting to Dashboard...")),
            );

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ParentDashBoard(userId: loginUserId)),
            );
            return;
          }
        }

        // ❌ If no valid parent details, move to DetailsPage


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ParentDashBoard(userId: loginUserId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Error: $e");
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
        List<Cookie> cookies = await cookieJar.loadForRequest(
            Uri.parse("https://1steptest.vercel.app/server/auth/google"));
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

          // ✅ Call Parent API
          var parentResponse = await dio.get(
            "https://1steptest.vercel.app/server/parent/getParent/$Id",
            options: Options(
              headers: {
                "Content-Type": "application/json",
                "Cookie": "access_token=$accessToken",
              },
            ),
          );

          print("Parent API Response: ${parentResponse.data}");
          print("Parent API Status Code: ${parentResponse.statusCode}");

          if (parentResponse.statusCode == 200 && parentResponse.data != null) {
            var parentData = parentResponse.data;

            // ❌ If "status": false, move to DetailsPage
            if (parentData.containsKey("status") &&
                parentData["status"] == false) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => DetailsPage(userId: Id)),
              );
              return;
            }

            // ✅ If parentDetails exist, move to ParentDashBoard
            if (parentData.containsKey("parentDetails")) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(
                    "Login successful! Redirecting to Dashboard...")),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => ParentDashBoard(userId: Id)),
              );
              return;
            }
          }

          // ❌ If no valid parent details, move to DetailsPage


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ParentDashBoard(userId: Id)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error: ${response.statusCode}")),
          );
        }

      }
    }
    catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect Username and Password")),
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
                      Text(
                        'Signin to access your account',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.greycolor,
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
                    fillColor: AppColors.textfieldcolor,
                  ),
                ),
                const SizedBox(height: 20),
                // Password TextField
                TextField(
                  style: TextStyle(
                    fontFamily: 'afacad',
                  ),
                  controller: passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.textfieldcolor,
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
                          activeColor: AppColors.primaryColor, // Set the checkbox color to blue
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
                          color: AppColors.primaryColor,
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
                      backgroundColor: AppColors.primaryColor,
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