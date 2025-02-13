import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:one_step/ParentScreens/EditParent.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(  // Fixes Bottom Overflow Issue
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,  // Ensures Left Alignment
              children: [
                SizedBox(height: 20),
                Center( // Centering the title
                  child: Text(
                    "My Profile",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center( // Centering Profile Picture
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('Assets/Images/profile.jpg'),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: AppColors.primaryColor,
                          child: Icon(Icons.edit, color: Colors.white, size: 15),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                Center( // Centering Name & Role
                  child: Column(
                    children: [
                      Text(
                        "Roma Johnson",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Parent",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Left-Aligned Menu Options
                _buildProfileOption(Icons.person, "Edit Profile", context, EditProfilePage()),
                _buildProfileOption(Icons.notifications, "Notifications", context, null),
                _buildProfileOption(Icons.favorite, "Favourites", context, null),
                _buildProfileOption(Icons.lock, "Change Password", context, null),
                _buildProfileOption(Icons.settings, "Settings", context, null),

                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    // Logout functionality
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
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, BuildContext context, Widget? targetPage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 0, right: 5), // Left aligned text
        leading: CircleAvatar(
          backgroundColor: Color(0xFFF3E5F6),
          child: Icon(icon, color: AppColors.primaryColor),
        ),
        title: Align(
          alignment: Alignment.centerLeft, // Ensures left alignment
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
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
}
