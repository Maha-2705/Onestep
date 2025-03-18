import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../AppColors.dart';
import '../../ParentScreens/Search/search_page.dart';
import '../Bookings/ProviderProfile.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  String fullName = ""; // Default text

  File? _imageFile;
  String? _downloadUrl;
  File? _profileImage;

  void initState() {
    super.initState();
    // Set status bar color for this page
    fetchParentprofile();
    fetchAppointments();

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
  List<Map<String, String>> upcomingAppointments = [
  ];

  void fetchAppointments() async {
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
        Uri.parse("https://1steptest.vercel.app/server/booking/getuserbookings/$Id"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> userBookings = jsonResponse["userBookings"];

        // Get today's date in YYYY-MM-DD format
        String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // Filter today's appointments only
        List<dynamic> todayAppointments = userBookings.where((booking) {
          String bookingDateStr = booking["scheduledTime"]["date"];
          DateTime bookingDate = DateTime.parse(bookingDateStr); // Convert string to DateTime
          String formattedBookingDate = DateFormat('yyyy-MM-dd').format(bookingDate);

          return formattedBookingDate == todayDate && (booking["status"] ?? "pending") == "pending";
        }).toList();

        if (todayAppointments.isNotEmpty) {
          var booking = todayAppointments.first; // Get only the first appointment

          String doctor = booking["providerDetails"]["fullName"] ?? "Unknown Doctor";
          List<dynamic> serviceList = booking["service"] ?? [];
          String specialty = serviceList.isNotEmpty ? serviceList.join(", ") : "General";

          String time = booking["scheduledTime"]["slot"] ?? "N/A";
          String location = booking["providerDetails"]["address"]["city"] ?? "Unknown Location";
          String profilePicture = booking["providerDetails"]["profilePicture"] ?? "";
          String providerId = booking["providerDetails"]["_id"] ?? "Unknown ID";

          setState(() {
            upcomingAppointments = [
              {
                "doctor": doctor,
                "specialty": specialty,
                "date": todayDate,
                "time": time,
                "location": location,
                "profilePicture": profilePicture,
                "providerId": providerId,
              }
            ];
          });
        } else {
          print("✅ No appointments found for today.");
          setState(() {
            upcomingAppointments = [];
          });
        }
      } else {
        print("❌ Failed to fetch appointments: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching appointments: $e");
    }
  }

// Function to format the date with year
  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('EEE, MMM d, yyyy').format(
        date); // Example: "Tue, Feb 25, 2025"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column( // Column for fixed header + scrolling content
          children: [
            Container( // Fixed Header Section
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
                            "Hi, $fullName",
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
                        radius: 26,
                        backgroundImage: _downloadUrl != null
                            ? NetworkImage(_downloadUrl!)
                            : AssetImage('Assets/Images/profile.jpg')
                        as ImageProvider,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchPage()),
                        );
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for trusted doctors near you...',
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            prefixIcon: Icon(
                                Icons.search, color: AppColors.greycolor),
                            suffixIcon: Icon(
                                Icons.filter_list, color: AppColors.greycolor),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    upcomingAppointments.isNotEmpty
                        ? Column(
                      children: upcomingAppointments.map((appointment) => UpcomingAppointmentCard(appointment: appointment)).toList(),
                    )
                        : Center(
                      child: Text(
                        "No appointments for today",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    )
,

                    SizedBox(height: 20),
                    TopDoctorsSection(),
                    SizedBox(height: 20),
                    ArticlesSection(), // New Articles Section
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  class ArticlesSection extends StatelessWidget {
  final List<Map<String, String>> articles = [
    {
      "title": "10 Tips for a Healthier Life",
      "author": "Dr. Sarah Johnson",
      "date": "Aug 25, 2023",
      "image": "Assets/Images/health1.jpg"
    },
    {
      "title": "How to Reduce Stress Daily",
      "author": "Dr. Mark Adams",
      "date": "Sep 10, 2023",
      "image": "Assets/Images/health2.jpg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Health Articles",
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
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            var article = articles[index];
            return _buildArticleCard(article);
          },
        ),
      ],
    );
  }

  Widget _buildArticleCard(Map<String, String> article) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Card(
        color: Color(0xFFEDE7F6), // Light Pink Color
        elevation: 2, // Adds shadow for a lifted effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  article["image"]!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article["title"]!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Ensure contrast
                      ),
                    ),
                    Text(
                      article["author"]!,
                      style: TextStyle(
                        color: Colors
                            .grey[800], // Slightly darker grey for better visibility
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      article["date"]!,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TopDoctorsSection extends StatefulWidget {
  @override
  _TopDoctorsSectionState createState() => _TopDoctorsSectionState();
}

class _TopDoctorsSectionState extends State<TopDoctorsSection> {
  final List<String> specialties = [
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

  String? selectedSpecialty;
  String currentCity = "Chennai"; // Default to Chennai
  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Fetch current city
  }

  /// **Fetch Current Location**
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          currentCity =
              placemarks[0].subAdministrativeArea ?? "Chennai"; // District Name
        });
        _fetchDoctors(
            specialties.first, currentCity); // Fetch default specialty data
      }
    } catch (e) {
      print("Error getting location: $e");
      _fetchDoctors(specialties.first, currentCity); // Fetch default if error
    }
  }

  /// **Fetch Doctors Based on Specialty & City**
  Future<void> _fetchDoctors(String specialty, String city) async {
    final Uri url = Uri.parse('https://1stepdev.vercel.app/server/provider/get')
        .replace(queryParameters: {'searchTerm': specialty, 'address': city});

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["providers"] != null) {
          setState(() {
            doctors = List<Map<String, dynamic>>.from(data["providers"]);
          });
          _fetchRatingsForProviders(); // Fetch ratings after fetching doctors
        }
      } else {
        print("Failed to fetch doctors: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching doctors: $e");
    }
  }

  /// **Fetch Ratings for Each Provider**
  Future<void> _fetchRatingsForProviders() async {
    for (int i = 0; i < doctors.length; i++) {
      String providerId = doctors[i]["_id"];
      try {
        final Uri url = Uri.parse(
            'https://1steptest.vercel.app/server/rating/getreview/$providerId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          var ratingData = json.decode(response.body);
          setState(() {
            doctors[i]["rating"] = ratingData["totalrating"] ?? "N/A";
            doctors[i]["reviews"] = ratingData["totalratings"] ?? 0;
          });
        } else {
          print('Failed to fetch ratings for provider $providerId');
        }
      } catch (error) {
        print('Error fetching rating for provider $providerId: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Top Therapists",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "See All",
                style: TextStyle(
                    color: AppColors.primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),

        // **Filter Chips**
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: specialties.map((specialty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(
                    specialty,
                    style: TextStyle(
                      color: selectedSpecialty == specialty
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  selected: selectedSpecialty == specialty,
                  selectedColor: AppColors.primaryColor,
                  onSelected: (selected) {
                    setState(() {
                      selectedSpecialty = selected ? specialty : null;
                      if (selectedSpecialty != null) {
                        _fetchDoctors(selectedSpecialty!, currentCity);
                      } else {
                        doctors.clear();
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 10),

        // **Doctor List or No Therapist Found Message**
        doctors.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "No therapist found",
              style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey),
            ),
          ),
        )
        :ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: doctors.length,
          itemBuilder: (context, index) {
            var doctor = doctors[index];
            return Column(
              children: [
                _buildDoctorCard(doctor, context),
                if (index < doctors.length - 1) Divider(thickness: 1, color: Colors.grey[300]), // Add divider except for the last item
              ],
            );
          },
        ),

      ],
    );
  }

  /// **Build Doctor Card**
  Widget _buildDoctorCard(Map<String, dynamic> doctor, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfilePage(providerId: doctor["_id"]),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: doctor["profilePicture"] != null
                  ? NetworkImage(doctor["profilePicture"])
                  : AssetImage("assets/default_avatar.png") as ImageProvider,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor["fullName"] ?? "Unknown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    doctor["name"] != null
                        ? doctor["name"].join(", ")
                        : "No specialties",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 18),
                      SizedBox(width: 5),
                      Text(doctor["rating"]?.toString() ?? "N/A"),
                      SizedBox(width: 5),
                      Text("${doctor["reviews"]} reviews"),
                      SizedBox(width: 20),

                      Icon(Icons.school_outlined, color: AppColors.primaryColor,
                          size: 18),
                      SizedBox(width: 5),

                      Text(
                          "${doctor?["experience"]} yrs experience",
                          style: TextStyle(fontSize: 14)),
                    ],
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

  class UpcomingAppointmentCard extends StatelessWidget {
  final Map<String, String> appointment;

  UpcomingAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upcoming Appointment",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: AppColors.textfieldcolor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, spreadRadius: 2)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: appointment["profilePicture"]!
                                .isNotEmpty
                                ? NetworkImage(appointment["profilePicture"]!)
                                : AssetImage(
                                "Assets/Images/doctor.jpg") as ImageProvider,
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment["doctor"]!,
                                style: TextStyle(fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                              Text(
                                appointment["specialty"]!,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        radius: 15,
                        child: Icon(Icons.phone, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.black54,
                                size: 18),
                            SizedBox(width: 8),
                            Text(
                              appointment["date"]!,
                              style: TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.black54,
                                size: 18),
                            SizedBox(width: 8),
                            Text(
                              appointment["time"]!,
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
