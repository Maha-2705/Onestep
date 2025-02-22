import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:one_step/ParentScreens/Bookingslot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../AppColors.dart';
import 'ReviewPage.dart';

class DoctorProfilePage extends StatefulWidget {
  final String providerId;

  DoctorProfilePage({required this.providerId});

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage> {
  Map<String, dynamic>? providerDetails;
  Map<String, dynamic>? providerratings;
  double totalRating = 0.0; // Store average rating
  int totalRatings = 0; // Store review count
  bool isLoading = true; // Loading state


  @override
  void initState() {
    super.initState();
    fetchProviderDetails();
    fetchratings();
  }
  Future<void> fetchratings() async {
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

      var response = await http
          .get(
        Uri.parse("https://1steptest.vercel.app/server/rating/getreview/${widget.providerId}"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      )
          .timeout(Duration(seconds: 10)); // ⏳ Timeout set to 10 seconds

      print("Response Status Code: ${response.statusCode}");
      print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);

        setState(() {
          totalRating = double.tryParse(jsonResponse['totalrating'].toString()) ?? 0.0;
          totalRatings = jsonResponse['totalratings'] ?? 0;
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch ratings: ${response.body}");
      }
    } catch (e) {
      if (e is TimeoutException) {
        print("⏳ Request timed out! Please check your network.");
      } else {
        print("❌ Error fetching ratings: $e");
      }
    }
  }

  Future<void> fetchProviderDetails() async {
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

      var response = await http
          .get(
        Uri.parse("https://1steptest.vercel.app/server/provider/get/${widget.providerId}"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      )
          .timeout(Duration(seconds: 10)); // ⏳ Timeout set to 10 seconds

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          providerDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch provider details: ${response.body}");
      }
    } catch (e) {
      if (e is TimeoutException) {
        print("⏳ Request timed out! Please check your network.");
      } else {
        print("❌ Error fetching provider details: $e");
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Therapist Details"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
          IconButton(icon: Icon(Icons.message), onPressed: () {}),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loader while fetching data
          : SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: providerDetails?["profilePicture"] != null
                      ? NetworkImage(providerDetails!["profilePicture"])
                      : AssetImage('') as ImageProvider,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      providerDetails == null
                          ? Container(
                        width: 120,
                        height: 20,
                        color: Colors.grey[300], // Placeholder
                      )
                          : Text(
                        providerDetails?["fullName"] ?? "",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      providerDetails == null
                          ? Container(
                        width: 100,
                        height: 16,
                        color: Colors.grey[300], // Placeholder
                      )
                          : Text(
                        providerDetails?["qualification"] ?? "",
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primaryColor, size: 18),
                          SizedBox(width: 8),
                          providerDetails == null
                              ? Container(
                            width: 80,
                            height: 14,
                            color: Colors.grey[300], // Placeholder
                          )
                              : Text(
                            providerDetails?["address"]?["city"] ?? "",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.school_outlined,
                              color: AppColors.primaryColor, size: 18),
                          SizedBox(width: 8),
                          providerDetails == null
                              ? Container(
                            width: 100,
                            height: 14,
                            color: Colors.grey[300], // Placeholder
                          )
                              : Text(
                              "${providerDetails?["experience"]} yrs experience",
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Divider(),
            Text("About", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            providerDetails == null
                ? Container(
              width: double.infinity,
              height: 50,
              color: Colors.grey[300], // Placeholder
            )
                : Text(providerDetails?["description"] ?? "",
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),

            SizedBox(height: 16),
            Text("Services", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            providerDetails == null
                ? Container(
              width: 100,
              height: 20,
              color: Colors.grey[300], // Placeholder
            )
                : Wrap(
              spacing: 10,
              runSpacing: 5,
              children: providerDetails?["name"]?.map<Widget>((service) {
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryColor),
                      SizedBox(width: 8),
                      Text(service, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              })?.toList() ?? [],
            ),

            SizedBox(height: 16),

            Text("Care Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            providerDetails == null
                ? Container(
              width: 150,
              height: 20,
              color: Colors.grey[300], // Placeholder
            )
                : Wrap(
              children: providerDetails?["therapytype"]?.map<Widget>((type) {
                IconData icon;
                switch (type.toLowerCase()) {
                  case "virtual":
                    icon = Icons.videocam;
                    break;
                  case "in-clinic":
                    icon = Icons.local_hospital;
                    break;
                  case "in-home":
                    icon = Icons.home;
                    break;
                  default:
                    icon = Icons.help_outline;
                }
                return Padding(
                  padding: EdgeInsets.only(right: 35),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: AppColors.primaryColor),
                      SizedBox(width: 5),
                      Text(type, style: TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              })?.toList() ?? [],
            ),

            SizedBox(height: 10),
            Divider(height: 30),
            Text("Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                providerDetails == null
                    ? Container(
                  width: 50,
                  height: 20,
                  color: Colors.white, // Placeholder
                )
                    : Row(
                  children: [
                    Text(
                      totalRating.toStringAsFixed(1),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.star, color: Colors.orange, size: 18),
                    Text(
                      " ($totalRatings Review${totalRatings > 1 ? 's' : ''})",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReviewPage(providerId:widget.providerId)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Text("ADD REVIEW"),
                ),
              ],
            ),

            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BookSlotPage(providerId:widget.providerId)),
                  );
                },
                child: Text('Book a Slot', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}