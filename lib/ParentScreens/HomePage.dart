import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../AppColors.dart';
import '../ParentScreens/search_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Set status bar color for this page
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryColor, // Set status bar color
      statusBarIconBrightness: Brightness.light, // Light icons for contrast
    ));
  }

  @override
  void dispose() {
    // Reset status bar color when leaving this page
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white, // Default color
      statusBarIconBrightness: Brightness.dark, // Dark icons for contrast
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, Maha!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Your Health, Your Choice – Start Now!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage('Assets/Images/profile.jpg'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () {

                      },
                      child: AbsorbPointer( // Prevents keyboard from opening when tapped
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for trusted doctors near you...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            prefixIcon: Icon(Icons.search, color: AppColors.greycolor),
                            suffixIcon: Icon(Icons.filter_list, color: AppColors.greycolor),
                          ),
                        ),
                      ),
                    ),
                  ),


                ],
              ),
            ),
            SizedBox(height: 20),

            UpcomingAppointmentCard(),
            SizedBox(height: 20),
// Add upcoming appointment card here
            TopDoctorsSection(),
          ],
        ),
      ),
    );
  }
}

class TopDoctorsSection extends StatelessWidget {
  final List<Map<String, String>> doctors = [
    {
      "name": "Dr. Jane Cooper",
      "specialty": "Dentist at Sadar Hospital",
      "rating": "4.5",
      "experience": "3 Years",
      "image": "Assets/Images/doctor1.jpg"
    },
    {
      "name": "Dr. Kristin Watson",
      "specialty": "Heart Specialist at Central Hospital",
      "rating": "4.8",
      "experience": "5 Years",
      "image": "Assets/Images/doctor.jpg"
    },

  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommended Title + See All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recommended",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "See All",
                style: TextStyle(color: AppColors.primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [

            ],
          ),
        ),
        SizedBox(height: 10),

        // Doctor List
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            var doctor = doctors[index];
            return _buildDoctorCard(doctor);
          },
        ),
      ],
    );
  }

  // Function to Build Filter Chip


  // Function to Build Doctor Card
  Widget _buildDoctorCard(Map<String, String> doctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // Doctor Image
          CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage(doctor["image"]!), // Replace with actual image
          ),
          SizedBox(width: 15),

          // Doctor Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor["name"]!,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  doctor["specialty"]!,
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 18),
                    SizedBox(width: 5),
                    Text(doctor["rating"]!),
                    SizedBox(width: 10),
                    Icon(Icons.calendar_today, color: AppColors.primaryColor, size: 18),
                    SizedBox(width: 5),
                    Text(doctor["experience"]!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class UpcomingAppointmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading for Upcoming Appointment
          Text(
            "Upcoming Appointment",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Heading color
            ),
          ),
          SizedBox(height: 10), // Spacing after heading

          // Appointment Card
          Container(
            decoration: BoxDecoration(
              color: AppColors.textfieldcolor, // Light grey background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[300]!, // Light grey border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Information Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage("Assets/Images/doctor.jpg"), // Replace with actual image
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Dr. Wade Warren",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Changed to black
                                ),
                              ),
                              Text(
                                "Neurology",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54, // Adjusted for better contrast
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Call Icon Button
                      CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        radius: 15,
                        child: Icon(Icons.phone, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  // Date and Time Row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Light grey background
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.black54, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Wed, April 24",
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.black54, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "09:00 - 10:00 AM",
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



