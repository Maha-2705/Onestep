import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:one_step/ParentScreens/EditParent.dart';

import 'FavouriteList.dart';

class ProfilePage extends StatelessWidget {
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
                // Center-Aligned Profile Picture
                Center(
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
                // Center-Aligned Name & Role
                Text(
                  "Your Name",
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
                    _buildProfileOption(Icons.lock, "Change Password", context, null),
                    _buildDivider(),
                    _buildProfileOption(Icons.settings, "Settings", context, null),
                  ],
                ),

                SizedBox(height: 20),
                // Center-Aligned Sign Out Button
                Center(
                  child: ElevatedButton.icon(
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
      padding: EdgeInsets.symmetric(horizontal: 0), // 10dp left & right padding
      width: double.infinity, // Full-width menu option
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
      padding: EdgeInsets.symmetric(horizontal: 0), // 10dp left & right padding
      child: Divider(color: Colors.grey[300], thickness: 1),
    );
  }
}
