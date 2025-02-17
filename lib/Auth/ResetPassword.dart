import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:one_step/Auth/Verifyotp.dart';

import '../AppColors.dart';

class ResetPasswordScreen extends StatefulWidget {
  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  Future<void> sendResetRequest() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      print("📤 Sending request with email: $email");

      final response = await http.post(
        Uri.parse("https://1stepdev.vercel.app/server/auth/otppassword"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ OTP sent successfully! Check your email.")),
          );
          // Navigate to VerifyOtpPage and pass the email
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(),
            ),
          );
        } else {
          String errorMessage = data["message"] ?? "Failed to send OTP.";
          print("❌ Backend Error Message: $errorMessage");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ $errorMessage")),
          );
        }
      } else {
        print("⚠️ Server responded with error: ${response.statusCode} - ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server error: ${response.statusCode}")),
        );
      }
    } catch (error) {
      print("❌ Network Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Network error. Please check your connection and try again.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:Colors.white ,
      appBar: AppBar(
        title: Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your email to receive a password reset OTP",
              style: TextStyle(fontSize: 16, color: AppColors.greycolor),
            ),
            SizedBox(height: 20),

            // Email TextField
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 20),

            // Terms and Conditions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("By continuing, you agree to our "),
                GestureDetector(
                  onTap: () {
                    // Navigate to Terms & Conditions Page (if implemented)
                  },
                  child: Text(
                    "Terms & Conditions",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 50),

            // Send Button with Loading Indicator
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendResetRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Send"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
