import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpVerificationScreen extends StatefulWidget {
  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  Future<void> verifyOtp() async {
    String email = emailController.text.trim();
    String otp = otpController.text.trim();
    String newPassword = newPasswordController.text.trim();

    if (email.isEmpty || otp.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    try {
      var url = Uri.parse(
          'https://1stepdev.vercel.app/server/auth/verifyOtp'); // Replace with your actual backend URL
      var body = jsonEncode({
        "email": email,
        "userEnteredOtp": otp,
        "newPassword": newPassword,
      });



      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );


      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated Successfully')),
        );
        // Navigate to the next screen if needed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify OTP')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text(
          '1step',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // White back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OTP VERIFICATION',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                'Check your email for OTP',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 20),
              _buildTextField(
                  'Your email', 'name@company.com', emailController, false),
              SizedBox(height: 15),
              _buildTextField(
                  'Enter your OTP', 'Enter your OTP', otpController, false),
              SizedBox(height: 15),
              _buildTextField('Enter New Password', 'Enter New Password',
                  newPasswordController, true),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Verify OTP',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint,
      TextEditingController controller, bool isPassword) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        SizedBox(height: 10),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[200],
            // Light grey fill color
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            enabledBorder: _boxShadow(),
            focusedBorder: _boxShadow(),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _boxShadow() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ).copyWith(
      borderSide: BorderSide.none,
    );
  }
}