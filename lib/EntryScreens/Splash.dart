import 'package:flutter/material.dart';
import 'dart:async';

import '../AppColors.dart';
import 'OnboardingScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingAndUser();
  }

  // Function to check if onboarding is completed and the user is logged in
  void _checkOnboardingAndUser() async {
    // Simulate a delay for the splash screen
    await Future.delayed(Duration(seconds: 3));

    // Navigate to OnboardingScreen if onboarding not completed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,  // Purple background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  // Center items vertically
          crossAxisAlignment: CrossAxisAlignment.center,  // Center items horizontally
          children: [
            // Image from assets
            Image.asset(
              'Assets/Images/pngegg.png',  // Replace with your image path
              width: 150,  // You can adjust the width as needed
              height: 150, // Adjust the height as needed
            ),
            SizedBox(height: 5),  // Space between image and text
            Text(
              'One Step',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'afacad',  // Set the Nunito font here
                color: Colors.white,  // Text color set to #5CD3E7
              ),
            ),
          ],
        ),
      ),
    );
  }
}
