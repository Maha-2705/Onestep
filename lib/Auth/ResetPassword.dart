import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

    final Uri url = Uri.parse("https://1steptest.vercel.app/server/auth/otppassword"); // Your backend API
    final Map<String, String> headers = {"Content-Type": "application/json"};
    final Map<String, dynamic> requestBody = {"email": email};

    try {
      print("🔹 Sending request to: $url");
      print("🔹 Request Headers: $headers");
      print("🔹 Request Body: ${jsonEncode(requestBody)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print("🔹 Response Status Code: ${response.statusCode}");
      print("🔹 Response Body: ${response.body}");

      // Decode the JSON response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["status"] == true) {
        // OTP successfully sent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("OTP sent successfully! Check your email.")),
        );

        print("✅ OTP: ${responseData["otp"]}"); // Debugging: Print OTP
      } else {
        // Handle error message from backend
        String errorMessage = responseData["message"] ?? "Unknown error occurred.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $errorMessage")),
        );
      }
    } catch (error) {
      print("❌ Network Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error. Please try again.")),
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
      appBar: AppBar(
        title: Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Color(0xFF65467C),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your email to receive a password reset OTP",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                      color: Color(0xFF65467C),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Send Button with Loading Indicator
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : sendResetRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF65467C),
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
