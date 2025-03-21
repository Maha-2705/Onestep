import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../AppColors.dart';

class ReviewPage extends StatefulWidget {
  final String providerId;

  ReviewPage({required this.providerId});
  @override

  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int selectedRating = 0;
  Map<String, dynamic>? providerDetails;
  Map<String, dynamic>? providerratings;
  double totalRating = 0.0; // Store average rating
  int totalRatings = 0; // Store review count
  bool isLoading = true; // Loading state
  final List<Map<String, dynamic>> ratingOptions = [
    {"icon": FontAwesomeIcons.thumbsDown, "label": "Strong No"},
    {"icon": FontAwesomeIcons.frown, "label": "No"},
    {"icon": FontAwesomeIcons.meh, "label": "Maybe"},
    {"icon": FontAwesomeIcons.smile, "label": "Yes"},
    {"icon": FontAwesomeIcons.thumbsUp, "label": "Strong Yes"},
  ];


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
  Future<void> postratings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? googleToken = prefs.getString('google_access_token');
    String? currentUserid = prefs.getString('ID');


    try {
      String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }

      // Construct the request body
      Map<String, dynamic> requestBody = {
        "_id": currentUserid, // Replace with the actual user ID
        "star": selectedRating, // Get selected rating
        "providerId": widget.providerId, // Replace with the actual provider ID
      };

      var response = await http
          .put(
        Uri.parse("https://1steptest.vercel.app/server/rating/review"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
        body: jsonEncode(requestBody), // Convert request body to JSON
      )
          .timeout(Duration(seconds: 10)); // ⏳ Timeout set to 10 seconds

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Rating updated successfully!"),
            duration: Duration(seconds: 2),
          ),
        );
        fetchratings();
      } else {
        print("❌ Failed to update rating: ${response.body}");
      }
    } catch (e) {
      if (e is TimeoutException) {
        print("⏳ Request timed out! Please check your network.");
      } else {
        print("❌ Error updating rating: $e");
      }
    }
  }
  // Emojis based on rating
  final List<String> ratingEmojis = [
    "😡", // 1 Star - Angry
    "🙁", // 2 Stars - Sad
    "😐", // 3 Stars - Neutral
    "🙂", // 4 Stars - Happy
    "🤩"  // 5 Stars - Excellent
  ];

  // Rating descriptions
  final List<String> ratingTexts = [
    "Terrible",
    "Bad",
    "Okay",
    "Good",
    "Excellent"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        title: Text('Review Page', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _profileSection(), // Profile section at the top
            SizedBox(height: 60),

            // Rating Box
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji Display
                  Text(
                    selectedRating > 0 ? ratingEmojis[selectedRating - 1] : "🌟",
                    style: TextStyle(fontSize: 40),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Tell us how was your Experience?",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Icon(
                          Icons.star,
                          size: 32,
                          color: index < selectedRating ? Colors.orange : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 10),

                  // Selected Rating Text
                  Text(
                    selectedRating > 0 ? ratingTexts[selectedRating - 1] : "",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 70),

            // Post Review Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedRating > 0 ? AppColors.primaryColor : Color(
                    0xFFE2D7EA),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 120),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // Post review functionality
                postratings(); // Call the function when the button is clicked

              },
              child: Text(
                'Post Review',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }


Widget _profileSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: providerDetails?["profilePicture"] != null
              ? NetworkImage(providerDetails?["profilePicture"]) // Network image
              : AssetImage('') as ImageProvider, // Fallback image
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                providerDetails?["fullName"] ?? "Unknown", // Full Name
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                providerDetails?["name"] is List
                    ? (providerDetails?["name"] as List).join(", ") // Convert list to a string
                    : providerDetails?["name"] ?? "Specialization not available",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // Allows the text to occupy up to 2 lines
                softWrap: true, // Enables wrapping within the available space
              ),
              SizedBox(height: 5),


              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primaryColor, size: 16),
                  Text(
                    providerDetails?["address"]?["city"] ?? "",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 5),

              Row(
    children: [
    Text(
    totalRating.toStringAsFixed(1),
    style: TextStyle(fontSize: 16),
    ),
    Icon(Icons.star, color: Colors.orange, size: 20),
    Text(
    " ($totalRatings Review${totalRatings > 1 ? 's' : ''})",
    style: TextStyle(fontSize: 14),
    ),
    ],
    ),
            ],
          ),
        ),
      ],
    );
  }

}
