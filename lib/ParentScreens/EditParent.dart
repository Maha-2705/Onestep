import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:http/http.dart' as http;
import 'package:one_step/Auth/SignInPage.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController servicesController = TextEditingController();
  final TextEditingController childNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController medicalHistoryController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController insuranceDetailsController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  List<String> selectedServices = [];
  List<String> allServices = []; // Will be fetched from the backend

  @override
  void initState() {
    super.initState();
    fetchParentDetails();
  }

  void fetchParentDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? Id = prefs.getString('user_id');
    String? googleToken = prefs.getString('google_access_token');


    try {
      String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }

      var response = await http.get(
        Uri.parse("https://1steptest.vercel.app/server/parent/getParent/$Id"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Raw Response Body: ${response.body}");

      // ✅ Allow both 200 & 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('parentDetails')) {
          var parentDetails = jsonResponse['parentDetails'];
          print("Extracted Parent Details: $parentDetails");

          setState(() {
            parentNameController.text = parentDetails['fullName'] ?? "";
            childNameController.text = parentDetails['childName'] ?? "";
            servicesController.text =
                (parentDetails['lookingFor'] as List<dynamic>?)?.join(", ") ??
                    "";
            dobController.text = parentDetails['dob']?.split("T")[0] ?? "";
            genderController.text = parentDetails['gender'] ?? "";
            heightController.text = parentDetails['height'] ?? "";
            weightController.text = parentDetails['weight'] ?? "";
            bloodGroupController.text = parentDetails['bloodGroup'] ?? "";
            medicalHistoryController.text =
                parentDetails['medicalHistory'] ?? "";
            allergiesController.text = parentDetails['allergies'] ?? "";
            phoneNumberController.text = parentDetails['phoneNumber'] ?? "";
            insuranceDetailsController.text = parentDetails['insurance'] ?? "";
            addressController.text = parentDetails['address'] ?? "";
          });
        } else {
          print("Error: 'parentDetails' key is missing in the response.");
        }
      } else {
        print("❌ Failed to fetch parent details: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching parent details: $e");
    }
  }


  void UpdateForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? Id = prefs.getString('user_id');
    String? Googleuserid = prefs.getString('GoogleUserId');
    print('Id: $Id');

    String? googleToken = prefs.getString('google_access_token');


    var regBody = {
      "isParent": true,
      "parentDetails": {
        "fullName": parentNameController.text,
        "lookingFor": servicesController.text,
        // Assuming this is a list
        "childName": childNameController.text,
        "dob": dobController.text,
        "gender": genderController.text,
        "height": heightController.text,
        "weight": weightController.text,
        "bloodGroup": bloodGroupController.text,
        "medicalHistory": medicalHistoryController.text,
        "allergies": allergiesController.text,
        "emergencyContact": phoneNumberController.text,
        // Assuming this is the emergency contact
        "insurance": insuranceDetailsController.text,
        "address": addressController.text,
        "phoneNumber": phoneNumberController.text,
        // Assuming this is the parent's phone number
      },
    };

    try {
      print('Sending request to server...');
      print('Request Body: $regBody');
      print('Access Token: $token');
      print('Google Access Token: $googleToken');

      // Construct Cookie Header
      String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }
      print('cookie token: $cookieHeader');

      var response = await http.post(
        Uri.parse(
            "https://1steptest.vercel.app/server/parent/updateparent/$Id"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
          // Send both tokens in cookies
        },
        body: jsonEncode(regBody),
      ).timeout(const Duration(seconds: 30)); // Reduced timeout for better UX

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle the response
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String message = jsonResponse['message'] ?? "Parent details updated successfully";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Check your connection.")),
      );
    }
  }

  DateTime? selectedDate;



  void _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF65467C),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Edit Profile", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.asset(
                  'Assets/Images/detailpic.png', height: 100)),
              SizedBox(height: 20),

              _buildHeading("Parent Name"),
              _buildTextField(parentNameController),

              _buildHeading("What Therapy are you looking for?"),
              _buildTextField(servicesController),

              _buildHeading("Child Name"),
              _buildTextField(childNameController),

              _buildHeading("Date of Birth                            Gender"),
              Row(
                children: [
                  Expanded(child: _buildDOBField()),
                  SizedBox(width: 10),
                  Expanded(
                      child: _buildSmallTextField(genderController, "Gender")),
                ],
              ),

              _buildHeading("Blood Group                             Phone Number"),
              _buildDoubleField(
                  bloodGroupController, "Blood Group", phoneNumberController,
                  "Phone Number"),

              _buildHeading("Height                                       Weight"),
              _buildDoubleField(
                  heightController, "Height", weightController, "Weight"),

              _buildHeading("Medical History"),
              _buildTextField(medicalHistoryController),

              _buildHeading("Allergies"),
              _buildTextField(allergiesController),

              _buildHeading("Insurance Details"),
              _buildTextField(insuranceDetailsController),

              _buildHeading("Address"),
              _buildTextField(addressController, maxLines: 2),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  UpdateForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF65467C),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 10, bottom: 5),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color:AppColors.textfieldcolor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.textfieldcolor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF65467C), width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDoubleField(TextEditingController controller1, String hint1,
      TextEditingController controller2, String hint2) {
    return Row(
      children: [
        Expanded(child: _buildSmallTextField(controller1, hint1)),
        SizedBox(width: 10),
        Expanded(child: _buildSmallTextField(controller2, hint2)),
      ],
    );
  }

  Widget _buildSmallTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      ),
    );
  }

  Widget _buildDOBField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextField(
          controller: dobController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            hintText: "Date of Birth",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
