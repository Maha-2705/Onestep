import 'package:flutter/material.dart';
import 'package:one_step/Auth/Parent/SignInPage.dart'; // Create this screen separately

import '../AppColors.dart';
import '../Auth/Provider/ProviderSignInPage.dart'; // Create this screen separately

class Chooseuser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen1(),
    );
  }
}

class OnboardingScreen1 extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen1> {
  int _currentIndex = 0;

  final List<Map<String, String>> slides = [
    {
      "image": "Assets/Images/parent.png",
      "title": "PARENT",
      "buttonText": "PARENT",
    },
    {
      "image": "Assets/Images/therapist.png",
      "title": "THERAPIST",
      "buttonText": "THERAPIST",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Title
            Text(
              "ONE STEP",
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'afacad',  // Set the Nunito font here
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            // Image and Navigation Arrows
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(slides[_currentIndex]["image"]!, height: 250),
                // Left Arrow
                Positioned(
                  left: 20,
                  child: Visibility(
                    visible: _currentIndex == 1,
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.pink,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                // Right Arrow
                Positioned(
                  right: 20,
                  child: Visibility(
                    visible: _currentIndex == 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: Container(
                        decoration: BoxDecoration(
                          color:AppColors.pink,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            // Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                if (_currentIndex == 0) {
                  // Navigate to SignInPage for Parent
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignInPage()),
                  );
                } else if (_currentIndex == 1) {
                  // Navigate to ProviderSignInPage for Therapist
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProviderSignInPage()),
                  );
                }
              },
              child: Text(
                slides[_currentIndex]["buttonText"]!,
                style: TextStyle(color: Colors.white, fontSize: 16,fontFamily:'afacad' ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
