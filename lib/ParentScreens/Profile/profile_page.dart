import 'dart:io';
import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


import '../../Auth/Parent/SignInPage.dart';
import '../Favourite/FavouriteList.dart';
import 'EditParent.dart';
import 'SettingScreen.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String fullName = ""; // Default text

  File? _imageFile;
  String? _downloadUrl;
  File? _profileImage;
  final picker = ImagePicker();

  String? userId; // To store the fetched user ID

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchParentprofile();


  }

  void signout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
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
        Uri.parse("https://1steptest.vercel.app/server/auth/signout"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      );



      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        // Clear stored user data
        await prefs.clear();

        // Navigate to the sign-in page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInPage()), // Replace with your sign-in screen
        );
      } else {
        print("❌ Failed to sign out: ${response.body}");
      }
    } catch (e) {
      print("❌ Error signing out: $e");
    }
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



      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('profilePicture')) {
          String profilePicUrl = jsonResponse['profilePicture'];
          fullName = jsonResponse['username']; // Update UI with full name

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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                // Center-Aligned Title
                Text(
                  "My Profile",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _downloadUrl != null && _downloadUrl!.isNotEmpty
                            ? NetworkImage(_downloadUrl!) // Load profile picture from the server
                            : AssetImage('Assets/Images/profile.jpg') as ImageProvider, // Default image
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.primaryColor,
                            child: Icon(Icons.edit, color: Colors.white, size: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                // Center-Aligned Name & Role
                 Text(
                  fullName, // Display fetched full name
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                Text(
                  "Parent",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

                // Left-Aligned Full-Width Menu Options with Padding
                Column(
                  children: [
                    _buildProfileOption(Icons.person, "Edit Profile", context, EditProfilePage()),
                    _buildDivider(),
                    _buildProfileOption(Icons.notifications, "Notifications", context, null),
                    _buildDivider(),
                    _buildProfileOption(Icons.favorite, "Favourites", context, FavouriteListScreen()),
                    _buildDivider(),
                    _buildProfileOption(Icons.settings, "Settings", context, ProfileSettingsScreen()),
                  ],
                ),

                SizedBox(height: 40),
                // Center-Aligned Sign Out Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Logout functionality
                      signout();
                    },
                    icon: Icon(Icons.logout),
                    label: Text("Sign Out"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, BuildContext context, Widget? targetPage) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0),
      width: double.infinity,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Color(0xFFF3E5F6),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          if (targetPage != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
            );
          }
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 0),
      child: Divider(color: Colors.grey[300], thickness: 1),
    );
  }
}
