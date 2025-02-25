import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:one_step/ProviderScreens/ProviderDashBoard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:flutter/material.dart';

import '../AppColors.dart';
import '../ParentScreens/HomePage.dart';

class ProviderDetailsPage extends StatefulWidget {
  final String userId;

  ProviderDetailsPage({required this.userId});

  @override
  _ProviderDetailsPageState createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  File? _profileImage;
  // Track selected time slots per weekday
  Map<String, List<String>> selectedSlotsPerDay = {
    "Mon": [],
    "Tue": [],
    "Wed": [],
    "Thu": [],
    "Fri": [],
    "Sat": [],
    "Sun": []
  };
  String selectedDay = "Mon"; // Default selected day

  // Time Slots categorized
  String selectedGap = "30 mins"; // Default selected gap

  final List<String> gapOptions = ["15 mins", "30 mins", "45 mins"];
  final List<String> morningSlots = ["07:00 AM", "07:30 AM", "08:00 AM", "08:30 AM", "09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM"];
  final List<String> afternoonSlots = ["12:00 PM", "12:30 PM", "01:00 PM", "01:30 PM", "02:00 PM", "02:30 PM", "03:00 PM", "03:30 PM"];
  final List<String> eveningSlots = ["04:00 PM", "04:30 PM", "05:00 PM", "05:30 PM", "06:00 PM", "06:30 PM", "07:00 PM"];

  // Function to toggle time slot selection
  void toggleTimeSlot(String slot) {
    setState(() {
      if (selectedSlotsPerDay[selectedDay]!.contains(slot)) {
        selectedSlotsPerDay[selectedDay]!.remove(slot);
      } else {
        selectedSlotsPerDay[selectedDay]!.add(slot);
      }
    });
  }
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  final TextEditingController providerNameController = TextEditingController();
  final TextEditingController providerEmailController = TextEditingController();
  final TextEditingController providerQualificationController = TextEditingController();
  final TextEditingController providerAddressController = TextEditingController();
  final TextEditingController providerStreetController = TextEditingController();
  final TextEditingController providerCountryController = TextEditingController();
  final TextEditingController providerStateController = TextEditingController();
  final TextEditingController providerCityController = TextEditingController();
  final TextEditingController providerPincodeController = TextEditingController();
  final TextEditingController providerFeeController = TextEditingController();
  final TextEditingController providerExperienceController = TextEditingController();
  final TextEditingController providerLicenseController = TextEditingController();
  final TextEditingController providerPhoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();


  final List<String> selectedServices = [];
  final List<String> selectedServiceTypes = [];

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

  final List<String> serviceTypeOptions = [
    'Clinic',
    'In-home',
    'Virtual'
  ];
  Future<void> submitForm() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('Access_token');
    String? googleToken = prefs.getString('Google_token');

    print('Google Token: $googleToken');

    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await uploadImageToFirebase(_profileImage!);
        if (imageUrl == null) {
          print("Image upload failed.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image upload failed. Please try again.")),
          );
          return;
        }
      }

      // Convert day abbreviations to full names
      final Map<String, String> dayMapping = {
        "Mon": "Monday",
        "Tue": "Tuesday",
        "Wed": "Wednesday",
        "Thu": "Thursday",
        "Fri": "Friday",
        "Sat": "Saturday",
        "Sun": "Sunday"
      };

      Map<String, List<String>> formattedTimeSlots = {};
      selectedSlotsPerDay.forEach((key, value) {
        formattedTimeSlots[dayMapping[key]!] = value;
      });

      print("Formatted Time Slots: $formattedTimeSlots"); // Debugging

      final Map<String, dynamic> requestBody = {
        "userRef": widget.userId,
        "profilePicture": imageUrl,
        "fullName": providerNameController.text,
        "email": providerEmailController.text,
        "qualification": providerQualificationController.text,
        "experience": providerExperienceController.text,
        "license": providerLicenseController.text,
        "phone": providerPhoneController.text,
        "description": _bioController.text,
        "name": selectedServices,
        "therapytype": selectedServiceTypes,
        "regularPrice": providerFeeController.text,
        "address": {
          "addressLine1": providerAddressController.text,
          "street": providerStreetController.text,
          "country": providerCountryController.text,
          "state": providerStateController.text,
          "city": providerCityController.text,
          "pincode": providerPincodeController.text,
        },
        "timeSlots": formattedTimeSlots,
      };

      print('Sending request to server...');
      print('Request Body: $requestBody');

      String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }

      print('Cookie Token: $cookieHeader');

      var response = await http.post(
        Uri.parse("https://1steptest.vercel.app/server/provider/create"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      var jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? "Provider details saved!")),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ProviderDashBoard()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(jsonResponse['message'] ?? "Failed to save provider details.")),
        );
      }
    } catch (e) {
      print('Error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Check your connection.")),
      );
    }
  }

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String filePath = 'profile_pictures/${DateTime.now().millisecondsSinceEpoch}.png';
      Reference ref = storage.ref().child(filePath);

      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/png'),
      );

      TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
      return await snapshot.ref.getDownloadURL(); // Get the image URL
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }


  void _nextPage() {
    if (_currentPage < 8) {
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
      backgroundColor: Color(0xFFE6E6E6),
      appBar: AppBar(
        title: Text("Provider Details - Step ${_currentPage + 1} of 9",
            style: TextStyle(fontFamily: 'afacad', color: Colors.white)),
        backgroundColor: AppColors.primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / 9,
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
                          buildProfileAndServicesPage(),
                          buildServiceTypePage(),
                          buildBasicInformationPage(),
                          buildLocationDetailsPage(),
                          buildFeeDetailsPage(),
                          buildExperiencePage(),
                          buildAuthenticationPage(),
                          buildTimeSlotPage(),
                          buildAboutPage(), // 9th Page Added


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

  // TimeSlot Selection Page - Improved UI
  Widget buildTimeSlotPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choose timeslots for bookings",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,fontFamily: 'afacad')),

            SizedBox(height: 10),

            // Selection Gap Box (with border only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Select Time Slot Gap:",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w500,fontFamily: 'afacad')),
                Container(
                  height: 35,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    border: Border.all(
                      color: AppColors.greycolor, // Border color
                      width: 1.0, // Border width
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: selectedGap,
                    items: gapOptions.map((String gap) {
                      return DropdownMenuItem<String>(
                        value: gap,
                        child: Text(gap),
                      );
                    }).toList(),
                    onChanged: (newGap) {
                      setState(() {
                        selectedGap = newGap!;
                      });
                    },
                    style: TextStyle(color: Colors.black,fontFamily: 'afacad'),
                    underline: SizedBox(), // Hide the underline
                  ),
                ),
              ],
            ),

            SizedBox(height: 15),
            // Day Selection Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedSlotsPerDay.keys.map((day) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text("$day (${selectedSlotsPerDay[day]!.length})"),
                      selected: selectedDay == day,
                      onSelected: (selected) {
                        setState(() {
                          selectedDay = day;
                        });
                      },
                      selectedColor:AppColors.primaryColor,
                      labelStyle: TextStyle(
                          color: selectedDay == day ? Colors.white : Colors.black),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 15),

            // Slot Sections
            buildTimeSlotCategory("Morning Slots", morningSlots),
            buildTimeSlotCategory("Afternoon Slots", afternoonSlots),
            buildTimeSlotCategory("Evening Slots", eveningSlots),

            SizedBox(height: 20),
            buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

// Function to generate categorized time slots
  Widget buildTimeSlotCategory(String title, List<String> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold,fontFamily: 'afacad')),
        SizedBox(height: 5),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: slots.map((time) {
            bool isSelected = selectedSlotsPerDay[selectedDay]!.contains(time);
            return GestureDetector(
              onTap: () => toggleTimeSlot(time),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFF3E5F6) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(time,
                    style: TextStyle(
                        color: isSelected ? Color(0xFF65467C) : Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Function to generate time slot buttons
  Widget buildTimeSlotButtons(List<String> slots) {
    return Wrap(
      spacing: 15,
      children: slots.map((time) {
        bool isSelected = selectedSlotsPerDay[selectedDay]!.contains(time);
        return ElevatedButton(
          onPressed: () => toggleTimeSlot(time),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Color(0xFF65467C) : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          ),
          child: Text(time),
        );
      }).toList(),
    );
  }


  Widget buildProfileAndServicesPage() {
    return buildPage(
      "Set Profile & Services",
      [
        Center( // Centering the profile avatar
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? Icon(Icons.person, size: 50, color: Colors.grey[700]) // Person icon instead of camera
                  : null,
            ),
          ),
        ),
        SizedBox(height: 20),
        buildServiceSelectionField(),
        SizedBox(height: 20),
        buildNavigationButtons(),
      ],
    );
  }


  Widget buildBasicInformationPage() {
    return buildPage("Basic Information", [
      buildTextField("Name", providerNameController),
      buildTextField("Email", providerEmailController),
      buildTextField("Qualification", providerQualificationController),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

  Widget buildLocationDetailsPage() {
    return buildPage("Location Details", [
      buildTextField("Address", providerAddressController),
      buildTextField("Street", providerStreetController),
      buildTextField("Country", providerCountryController),
      buildTextField("State", providerStateController),
      buildTextField("City", providerCityController),
      buildTextField("Pincode", providerPincodeController),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

  Widget buildFeeDetailsPage() {
    return buildPage("Fee Details", [
      buildTextField("Fees per Appointment", providerFeeController),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

  Widget buildExperiencePage() {
    return buildPage("Years of Experience", [
      buildTextField("Experience (in years)", providerExperienceController),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

  Widget buildAuthenticationPage() {
    return buildPage("Authentication", [
      buildTextField("Licensing", providerLicenseController),
      buildTextField("Phone Number", providerPhoneController),
      SizedBox(height: 20),
      buildNavigationButtons(),
    ]);
  }

  Widget buildPage(String title, List<Widget> children) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'afacad')),
            SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
  Widget buildAboutPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("About", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Biography", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.textfieldcolor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
            child:TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a short biography...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
        ),
            SizedBox(height: 20),
            buildNavigationButtons(isLastPage: true),
          ],
        ),
      ),
    );
  }Widget buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'afacad',
            ),
          ),
          SizedBox(height: 5),
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: AppColors.textfieldcolor,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildServiceTypePage() {
    return buildPage(
      "Service Type Selection",
      [
        Text(
          "Please select your service type",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10), // Adds spacing
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: serviceTypeOptions.map((type) {
            bool isSelected = selectedServiceTypes.contains(type);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    selectedServiceTypes.remove(type);
                  } else {
                    selectedServiceTypes.add(type);
                  }
                });
              },
              child: Container(
                width: double.infinity, // Make the container fill the available width
                height: 43,
                margin: EdgeInsets.symmetric(vertical: 5), // Adjust vertical spacing
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFFF3E5F6) : Colors.white, // Light purple when selected
                  border: Border.all(color: Colors.grey.shade300, width: 2), // Border
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                padding: EdgeInsets.all(8),
                child: Text(
                  type,
                  style: TextStyle(fontSize: 14, fontFamily: 'afacad'),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
        buildNavigationButtons(),
      ],
    );
  }

  Widget buildServiceSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your services',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentPage > 0)
          ElevatedButton(
            onPressed: _prevPage,
            style: ButtonStyle(
              side: MaterialStateProperty.all(BorderSide(color: AppColors.primaryColor, width: 2)),
              backgroundColor: MaterialStateProperty.all(Colors.white),
              foregroundColor: MaterialStateProperty.all(AppColors.primaryColor),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))), // Light curve
            ),
            child: Text("Back"),
          ),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: isLastPage ? submitForm : _nextPage, // Call submitForm() when it's the last page

              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(AppColors.primaryColor),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))), // Light curve
              ),
              child: Text(isLastPage ? "Submit" : "Next"),
            ),
          ),
        ),
      ],
    );
  }


}
