import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import 'package:one_step/Auth/SignInPage.dart';
import 'package:velocity_x/velocity_x.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'ParentDashBoard.dart'; // Package for country picker

class DetailsPage extends StatefulWidget {

  @override
  _MultiStepFormState createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<DetailsPage> {

  PageController _pageController = PageController();
  int _currentPage = 0;

  final TextEditingController parentNameController = TextEditingController();
  final List<String> selectedServices = [];
  final TextEditingController childNameController = TextEditingController();
  DateTime? selectedDOB;
  String? selectedGender;
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bloodGroupController = TextEditingController();
  final TextEditingController medicalHistoryController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController EmergencyController = TextEditingController();

  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController insuranceController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final List<String> serviceOptions = [
    'Diagnostic Evaluation',
    'Occupational Therapy',
    'Dance Movement',
    'Speech Therapy',
    'Counselling',
    'School-Based Service',
    'Music Therapy',
    'Art As Therapy',
    'ABA Therapy',
    'Social Skills Group'
  ];
  void SubmitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? Id = prefs.getString('Id');

    if (token == null || token.isEmpty) {
      VxToast.show(context, msg: "Session expired! Please log in again.");
      return;
    }

    var regBody = {
      "isParent": true,
      "parentDetails": {
        "fullName": parentNameController.text,
        "lookingFor": selectedServices, // Assuming this is a list
        "childName": childNameController.text,
        "dob": selectedDOB != null ? selectedDOB!.toIso8601String() : "",
        "gender": selectedGender,
        "height": heightController.text,
        "weight": weightController.text,
        "bloodGroup": bloodGroupController.text,
        "medicalHistory": medicalHistoryController.text,
        "allergies": allergiesController.text,
        "emergencyContact": phoneNumberController.text, // Assuming this is the emergency contact
        "insurance": insuranceController.text,
        "address": addressController.text,
        "phoneNumber": phoneNumberController.text, // Assuming this is the parent's phone number
      },
    };

    try {
      print('Sending request to server...');
      print('Request Body: $regBody');
      print('Access Token: $token');

      var response = await http.post(
        Uri.parse("https://1steptest.vercel.app/server/parent/createparent/$Id"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": "access_token=$token", // Send token as a cookie
        },
        body: jsonEncode(regBody),
      ).timeout(const Duration(seconds: 30)); // Reduced timeout for better UX

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Handle the response
      var jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 201 && jsonResponse['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? "Parent details saved")),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ParentDashBoard()));
      }

    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Check your connection.")),
      );
    }
  }
  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage++;
      });
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() {
        _currentPage--;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6E6E6), // Set background color to light grey
      appBar: AppBar(
        title: Text("${_currentPage + 1} of 5 Question", style: TextStyle(fontFamily: 'afacad',color: Colors.white)),
        backgroundColor: Color(0xFF65467C),
        automaticallyImplyLeading: false, // Remove the back arrow
        elevation: 0, // Flat design
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4C525D)),
              backgroundColor: Colors.grey[400],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          buildParentInfoPage(),
                          buildChildInfoPage(),
                          buildPhysicalInfoPage(),
                          buildMedicalInfoPage(),
                          buildContactInfoPage(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildParentInfoPage() {
    return buildPage("Parent Information", [
      buildTextField("Parent Name", parentNameController),
      buildServiceSelectionField(),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

  Widget buildChildInfoPage() {
    return buildPage("Child Information", [
      buildTextField("Child Name", childNameController),
      SizedBox(height: 10),

      buildDatePickerField("Date of Birth", selectedDOB, (date) => setState(() => selectedDOB = date)),
      SizedBox(height: 20),

      buildDropdownField("Gender", ['Male', 'Female', 'Other'], (value) => setState(() => selectedGender = value!), selectedGender),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

Widget buildPhysicalInfoPage() {
    return buildPage("Physical Information", [
      buildTextField("Height (in cm)", heightController),
      buildTextField("Weight (in kg)", weightController),
      buildTextField("Blood Group", bloodGroupController),
      SizedBox(height: 20),

      buildNavigationButtons(),
    ]);
  }

  Widget buildMedicalInfoPage() {
    return buildPage("Medical Information", [
      buildTextField("Medical History", medicalHistoryController),

      buildTextField("Allergies", allergiesController),
      SizedBox(height: 10),
      buildTextField("Emergency Contact", EmergencyController, maxLines: 1),

      SizedBox(height: 10),

      buildTextField("Insurance Details", insuranceController),
      SizedBox(height: 20),

      buildNavigationButtons(),
    ]);
  }

  Widget buildContactInfoPage() {
    return buildPage("Contact Information", [
      buildTextField("Address", addressController, maxLines: 3),
      SizedBox(height: 20),
      buildPhoneNumberField(), // Country Picker Added

      SizedBox(height: 20),

      buildNavigationButtons(isLastPage: true),
    ]);
  }


  Widget buildPage(String title, List<Widget> children) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'afacad')),
            SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
  Widget buildDatePickerField(String label, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.0), // Added padding
          child: Text(label, style: TextStyle(fontSize: 16, fontFamily: 'afacad')),
        ),
        SizedBox(height: 5),
        Container(
          height: 45, // Set the height for the field
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              onDateSelected(pickedDate);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: "Select a date",

                hintStyle: TextStyle(fontSize: 14,fontFamily: 'afacad'), // Optional: Customize the hint text style if needed

                border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Adjusted contentPadding for vertical centering
              ),
              child: Text(
                selectedDate != null ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}" : "Select a date",
                textAlign: TextAlign.start, // Ensure text is aligned properly
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget buildPhoneNumberField() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.0),
      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8.0), // Added padding
            child: Text("Phone Number", style: TextStyle(fontSize: 16, fontFamily: 'afacad')),
          ),
          SizedBox(height: 5),
          Container(
            height: 45,
            padding: EdgeInsets.only(top: 5.0), // Added 10px padding at the top
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(top: 10.0), // Added 5px padding
              child: IntlPhoneField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(

                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                  hintText: "Enter phone number",

                  hintStyle: TextStyle(fontSize: 14,fontFamily: 'afacad'), // Optional: Customize the hint text style if needed
                  contentPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0), // Adjusted contentPadding for centering the hint text
                ),
                initialCountryCode: 'IN', // Set default country
                onChanged: (phone) {
                  phoneNumberController.text = phone.completeNumber;
                },
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdownField(String label, List<String> options, Function(String?) onChanged, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.0), // Added padding
          child: Text(label, style: TextStyle(fontSize: 16, fontFamily: 'afacad')),
        ),
        SizedBox(height: 5),
        Container(
          height: 45, // Set the height for the field
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0), // Adjusted contentPadding for vertical centering
            ),
            value: value,
            items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }


  Widget buildTextField(String label, TextEditingController controller, {String? hintText, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16, fontFamily: 'afacad'),
          ),
          SizedBox(height: 5),
          Container(
            height: 45, // Set the height for the field
            decoration: BoxDecoration(
              color: Colors.grey[200], // Light grey background
              borderRadius: BorderRadius.circular(5), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.black12, // Shadow color
                  blurRadius: 4, // Blur intensity
                  offset: Offset(2, 2), // Shadow position
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                labelStyle: TextStyle(fontFamily: 'afacad'),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(5), borderSide: BorderSide.none),

                fillColor: Colors.grey[200], // Light grey background
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              ),
              maxLines: maxLines,
            ),
          ),
        ],
      ),
    );
  }


  Widget buildServiceSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What service are you looking for?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'afacad'),
        ),
        SizedBox(height: 8),
        Container(
          height: 350,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: serviceOptions.length,
            itemBuilder: (context, index) {
              bool isSelected = selectedServices.contains(serviceOptions[index]);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedServices.remove(serviceOptions[index]);
                    } else {
                      selectedServices.add(serviceOptions[index]);
                    }
                  });
                },
                child: Container(
                  height: 43,
                  margin: EdgeInsets.symmetric(vertical: 5), // Space between each item
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFFF3E5F6) : Colors.white, // Light purple when selected
                    border: Border.all(color:  Colors.grey.shade300, width: 2), // Border
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  padding: EdgeInsets.all(8),
                  child: Text(
                    serviceOptions[index],
                    style: TextStyle(fontSize: 14, fontFamily: 'afacad'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget buildNavigationButtons({bool isLastPage = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 30.0),
      child: Row(
        mainAxisAlignment: _currentPage == 0 ? MainAxisAlignment.end : MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            OutlinedButton(
              onPressed: _prevPage,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Color(0xFF65467C), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              child: Text("Back", style: TextStyle(color: Color(0xFF65467C))),
            ),
          ElevatedButton(
            onPressed: () {
              if (isLastPage) {
                SubmitForm(); // Call API when submitting the last page
              } else {
                _nextPage();
              }
            },


            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF65467C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
            ),
            child: Text(isLastPage ? "Submit" : "Next", style: TextStyle(color: Colors.white,fontFamily: 'afacad')),
          ),
        ],
      ),
    );
  }
}
