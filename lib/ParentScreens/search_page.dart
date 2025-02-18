import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../AppColors.dart';
import 'ProviderProfile.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<Map<String, dynamic>> servicesList = [];
  bool isLoading = true;     // Loading state



  final List<Map<String, dynamic>> services = [
    {"value": "Diagnostic Evaluation", "label": "Diagnostic Evaluation"},
    {"value": "Occupational Therapy", "label": "Occupational Therapy"},
    {"value": "Dance Movement", "label": "Dance Movement"},
    {"value": "Speech Therapy", "label": "Speech Therapy"},
    {"value": "School-Based Service", "label": "School-Based Service"},
    {"value": "Music Therapy", "label": "Music Therapy"},
    {"value": "Art As Therapy", "label": "Art As Therapy"},
    {"value": "ABA Therapy", "label": "ABA Therapy"},
    {"value": "Art as Therapy", "label": "Art as Therapy"},
    {"value": "Counselling", "label": "Counselling"},
    {"value": "Social Skills Group", "label": "Social Skills Group"},
  ];

  TextEditingController _whatController = TextEditingController();
  TextEditingController _whereController = TextEditingController();
  bool _isSearchInitiated = false;

  void _searchService() async {
    String service = _whatController.text.trim();
    String city = _whereController.text.trim();

    if (service.isNotEmpty && city.isNotEmpty) {
      setState(() {
        isLoading = true; // Start loading before fetching data
        _isSearchInitiated = true;
      });

      final Uri url = Uri.parse(
        'https://1stepdev.vercel.app/server/provider/get',
      ).replace(queryParameters: {
        'searchTerm': service,
        'address': city,
      });

      print('Fetching data from: $url'); // Debugging log

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          print('Response Data: $data'); // Debugging log

          if (mounted) {
            setState(() {
              servicesList.clear();
              if (data.containsKey('providers')) {
                servicesList = data['providers'].map<Map<String, dynamic>>((provider) {
                  return {
                    "id": provider["_id"],
                    "profilePicture": provider["profilePicture"],
                    "name": provider["fullName"] ?? "Unknown",
                    "service": provider["name"]?.join(", ") ?? "No service specified",
                    "location": "${provider["address"]["city"]}, ${provider["address"]["state"]}",
                    "experience": "${provider["experience"] ?? 0} years",
                    "availability": provider["therapytype"]?.join(", ") ?? "N/A",
                    "rating": "N/A",  // Placeholder (will be updated)
                    "reviews": 0, // Placeholder (will be updated)
                    "price": "₹${provider["regularPrice"] ?? "N/A"}",
                  };
                }).toList();

                // Fetch ratings for each provider
                _fetchRatingsForProviders();
              } else {
                print('Unexpected response format: $data');
              }
            });
          }
        } else {
          print('Failed to load data: ${response.statusCode}, Response: ${response.body}');
        }
      } catch (error) {
        print('Error fetching data: $error');
      }

      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading after fetching data
        });
      }
    } else {
      print('Please enter both service and city.');
    }
  }

  // 🔥 Fetch Ratings for Each Provider
  void _fetchRatingsForProviders() async {
    for (int i = 0; i < servicesList.length; i++) {
      String providerId = servicesList[i]["id"];
      try {
        final Uri url = Uri.parse('https://1steptest.vercel.app/server/rating/getreview/$providerId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          var ratingData = json.decode(response.body);
          setState(() {
            servicesList[i]["rating"] = ratingData["totalrating"] ?? "N/A";
            servicesList[i]["reviews"] = ratingData["totalratings"] ?? 0;
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                '1step',
                style: TextStyle(color: Colors.white, fontSize: 20),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(),
            SizedBox(height: 20),
            Text(
              'Searching Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            Expanded(
              child: !_isSearchInitiated
                  ? Center(
                child: SizedBox(
                  width: 200, // Set the width of the image
                  height: 200, // Set the height of the image
                  child: Image.asset('Assets/Images/searchimg.png', fit: BoxFit.cover), // Your image before search
                ),
              )
                  : isLoading
                  ? Center(
                child: CircularProgressIndicator(), // Show loading indicator
              )
                  : servicesList.isNotEmpty
                  ? ListView.builder(
                itemCount: servicesList.length,
                itemBuilder: (context, index) {
                  return _buildServiceCard(servicesList[index]);
                },
              )
                  : Center(
                child: Text(
                  'Provider not found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }


  Widget _buildSearchBox() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 10),

            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Container(
                    width: 500, // Set your desired width
                    child: TextField(
                      controller: _whatController,
                      onTap: () {
                        _showServicePopup(context);
                      },
                      decoration: InputDecoration(
                        hintText: 'Diagnostic Evaluation',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: 30),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _whereController,
                    decoration: InputDecoration(
                      hintText: 'Chennai',
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: _searchService,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(service["profilePicture"]),
                  radius: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service["name"],
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        service["service"],
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.favorite_border),
              ],
            ),
            SizedBox(height: 10),

            // 📍 Location with icon
            Row(
              children: [
                Icon(
                    Icons.location_on, color: AppColors.primaryColor, size: 16),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                      service["location"], style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            SizedBox(height: 5),

            // 🎓 Experience with icon
            Row(
              children: [
                Icon(Icons.school, color: AppColors.primaryColor, size: 16),
                SizedBox(width: 5),
                Text(service["experience"], style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 5),

            // 🖥️ Availability with icon
            Row(
              children: [
                Icon(Icons.video_call, color: AppColors.primaryColor, size: 16),
                SizedBox(width: 5),
                Text(service["availability"], style: TextStyle(fontSize: 12)),
              ],
            ),
            SizedBox(height: 5),

            // ⭐ Reviews with star icons
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                SizedBox(width: 5),
                Text(
                  "${service["rating"]}  (${service["reviews"]} reviews)",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  service["price"],
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    // Print the _id to the console for debugging
                    print("Provider ID: ${service["id"]}");

                    // Pass the _id when navigating to the profile screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorProfilePage(
                          providerId: service["id"], // Pass the _id
                        ),
                      ),
                    );
                  },

                  child: Text(
                    "View Profile",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showServicePopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Service"),
          content: Container(
            width: double.maxFinite, // Ensures it takes full width
            constraints: BoxConstraints(
              maxHeight: 300, // Set medium height
            ),
            child: SingleChildScrollView(
              child: ListBody(
                children: services.map((service) {
                  return ListTile(
                    leading: Text(
                      "•", // Bullet symbol
                      style: TextStyle(fontSize: 18),
                    ),
                    title: Text(service["label"]),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _whatController.text = service["value"];
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }


}
