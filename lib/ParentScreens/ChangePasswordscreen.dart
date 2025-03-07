import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../AppColors.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  bool _isObscureOld = true;
  bool _isObscureNew = true;


  Future<void> resetPassword() async {
    if (oldPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "All fields are required");
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('access_token');
    String? Id = prefs.getString('user_id');
    String? googleToken = prefs.getString('google_access_token');


    String cookieHeader = "";
    if (token != null && token.isNotEmpty) {
      cookieHeader += "access_token=$token;";
    }
    if (googleToken != null && googleToken.isNotEmpty) {
      cookieHeader += "google_access_token=$googleToken;";
    }

    try {
      final response = await http.post(
        Uri.parse("https://1steptest.vercel.app/server/user/resetpassword/$Id"),
        // Replace with actual API
        headers: {"Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
        body: jsonEncode({
          "password": oldPasswordController.text,
          "newPassword": newPasswordController.text,
        }),
      );
      print("Response Status Code: ${response.statusCode}");
      print("Raw Response Body: ${response.body}");


      final data = jsonDecode(response.body);

      if (data["success"] == false) {
        Fluttertoast.showToast(msg: data["message"]);
        return;
      }

      Fluttertoast.showToast(msg: "Password changed successfully");
      oldPasswordController.clear();
      newPasswordController.clear();
    } catch (error) {
      Fluttertoast.showToast(msg: "Error: ${error.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Reset Password",
          style: TextStyle(color: Colors.white, fontSize: 19),
        ),
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white), // Back arrow color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),

              // Centered Image
              Center(
                child: Image.asset(
                  'Assets/Images/reset.png',
                  // Replace with your actual image path
                  height: 200, // Adjust size as needed
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20),

              // Old Password Heading
              Text(
                "Old Password",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // Old Password Field with Box Design
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: oldPasswordController,
                  obscureText: _isObscureOld,
                  decoration: InputDecoration(
                    hintText: "Enter your old password",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscureOld ? Icons.visibility_off : Icons
                          .visibility),
                      onPressed: () {
                        setState(() {
                          _isObscureOld = !_isObscureOld;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // New Password Heading
              Text(
                "New Password",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // New Password Field with Box Design
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: newPasswordController,
                  obscureText: _isObscureNew,
                  decoration: InputDecoration(
                    hintText: "Enter your new password",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    suffixIcon: IconButton(
                      icon: Icon(_isObscureNew ? Icons.visibility_off : Icons
                          .visibility),
                      onPressed: () {
                        setState(() {
                          _isObscureNew = !_isObscureNew;
                        });
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text("CANCEL", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  SizedBox(width: 20), // Space between buttons

                  // Confirm Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle confirm logic
                        resetPassword();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text("CONFIRM",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}