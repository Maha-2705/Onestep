import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../AppColors.dart';
import 'ChangePasswordscreen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final TextEditingController NameController = TextEditingController();
  final TextEditingController EmailController = TextEditingController();
  String fullName = ""; // Default text
  String Email = ""; // Default text
  String? userId; // To store the fetched user ID

  File? _imageFile;
  String? _downloadUrl;
  File? _profileImage;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchParentprofile();
  }


  void fetchParentprofile() async {
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
        Uri.parse("https://1steptest.vercel.app/server/user/$Id"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      );

      print("Response Status Code: ${response.statusCode}");
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('profilePicture')) {
          String profilePicUrl = jsonResponse['profilePicture'];
          fullName = jsonResponse['username']; // Update UI with full name
          Email = jsonResponse['email']; // Update UI with full name


          print("Extracted Profile Picture URL: $profilePicUrl");

          setState(() {
            _downloadUrl = profilePicUrl; // Update the image URL
          });
        } else {
          print("Error: 'profilePicture' key is missing in the response.");
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

    String? googleToken = prefs.getString('google_access_token');


    var regBody = {

      "username": NameController.text,
      "email": EmailController.text,
      // Assuming this is a list


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
            "https://1steptest.vercel.app/server/user/update/$Id"),
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
        String message = jsonResponse['message'] ?? "Updated successfully";

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

  // Function to load user ID from SharedPreferences
  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id');
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _updateProfileImageUrl();
    }
  }

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String filePath = 'profile_pictures/${DateTime
          .now()
          .millisecondsSinceEpoch}.png';
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


  Future<void> _updateProfileImageUrl() async {
    if (userId == null) return;

    final String apiUrl = "https://1steptest.vercel.app/server/user/update/$userId";
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? googleToken = prefs.getString('google_access_token');

    String cookieHeader = "";
    if (token != null && token.isNotEmpty) {
      cookieHeader += "access_token=$token;";
    }
    if (googleToken != null && googleToken.isNotEmpty) {
      cookieHeader += "google_access_token=$googleToken;";
    }

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

      // **Update the displayed profile image URL**
      setState(() {
        _downloadUrl = imageUrl;
      });
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
        body: jsonEncode({"profilePicture": imageUrl}),
      );

      if (response.statusCode == 200) {
        print("Profile image updated successfully!");
      } else {
        print("Failed to update profile image");
      }
    } catch (e) {
      print("Error updating profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView( // Wrap Column in SingleChildScrollView
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Gradient Background with Curve
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 60,
                  left: 16,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // "Profile Settings" Title
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Profile Settings",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Profile Image Positioned Below
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: _downloadUrl != null
                                ? NetworkImage(_downloadUrl!)
                                : AssetImage('Assets/Images/profile.jpg')
                            as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,

                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 80), // Adjust spacing for username and email

            // Username, Email, and Save Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username
                  Text("User Name",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    controller: NameController..text = fullName,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Email
                  Text("Email",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  TextField(
                    controller: EmailController..text = Email,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
// Change Password Text
                  SizedBox(height: 30),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
                        );
                      },
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor, // Set text color to purple
                          decoration: TextDecoration.underline, // Add underline for better UX
                        ),
                      ),
                    ),
                  ),


                  SizedBox(height: 70),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        UpdateForm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}