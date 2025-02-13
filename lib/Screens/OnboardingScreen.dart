import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:one_step/Screens/ChooseUser.dart';

import '../AppColors.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0; // 0 = First page, 1 = Second page

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => Chooseuser()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),
            // Page Heading
            Text(
              currentPage == 0 ? "How One Step Works?" : "Steps To Start Your Therapy Journey",
              style: TextStyle(
                fontSize: 22.0,
                fontFamily: 'afacad',  // Set the Nunito font here
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            // Page Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: currentPage == 0
                      ? _getFirstPageContent()
                      : _getSecondPageContent(),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Navigation Arrows
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Arrow (Hidden on first page)
                  currentPage == 0
                      ? SizedBox.shrink()
                      : Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor, // Same color as forward button
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          currentPage = 0;
                        });
                      },
                    ),
                  ),

                  // Forward Arrow
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: () {
                        if (currentPage == 0) {
                          setState(() {
                            currentPage = 1;
                          });
                        } else {
                          _completeOnboarding();
                        }
                      },
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

  // First Page Content
  List<Widget> _getFirstPageContent() {
    return [
      _buildStep("Discover top therapist profiles", "Explore profiles of top therapists and find the perfect match for your needs", "Assets/Images/onboarding1.png", true),
      _buildStep("Take our quick questionnaire", "Answer a few questions to connect with the best therapist for you.", "Assets/Images/onboarding2.png", false),
      _buildStep("Schedule Your Session", "Easily book your therapy appointment in just a few taps.", "Assets/Images/onboarding3.png", true),
    ];
  }

  // Second Page Content
  List<Widget> _getSecondPageContent() {
    return [
      _buildStep("Create Your Therapist Profile", "Build a profile that highlights your specializations, experience, and the unique care you offer", "Assets/Images/onboarding4.png", false),
      _buildStep("Set Your Therapy Conditions", "You have complete control over your schedule, session fees, and therapeutic approach. Update Your Therapy Conditions", "Assets/Images/onboarding5.png", true),
      _buildStep("Start Helping Clients", "Once your profile is live, begin offering therapy sessions and making a difference", "Assets/Images/onboarding6.png", false),
    ];
  }

  // Step Widget with Alternating Layout
  Widget _buildStep(String title, String description, String imagePath, bool isImageRight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Row(
        children: isImageRight
            ? [
          Expanded(child: _buildTextContent(title, description)),
          SizedBox(width: 10),
          Image.asset(imagePath, height: 160, width: 160),
        ]
            : [
          Image.asset(imagePath, height: 160, width: 160),
          SizedBox(width: 10),
          Expanded(child: _buildTextContent(title, description)),
        ],
      ),
    );
  }

  // Text Content for Each Step
  Widget _buildTextContent(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.0,
            fontFamily: 'afacad',  // Set the Nunito font here
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(
            fontSize: 14.0,
            fontFamily: 'afacad',  // Set the Nunito font here
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
