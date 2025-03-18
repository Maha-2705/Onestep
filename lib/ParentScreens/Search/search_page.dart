import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../Bookings/ProviderProfile.dart';



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


      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          var data = json.decode(response.body);

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
      backgroundColor: Colors.white,
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
              'Search Results',
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
  final GlobalKey _searchBoxKey = GlobalKey();
  Widget _buildSearchBox() {
    return Center(
      child: Container(
        key: _searchBoxKey, // Assign key to find its position
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10), // Smaller radius
          border: Border.all(color: Colors.grey.shade300, width: 1.5), // Added border
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2, // Reduced blur
              spreadRadius: 1, // Reduced spread
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.health_and_safety_outlined, color: Colors.grey, size: 18), // Smaller icon
            SizedBox(width: 6),
            Container(
              width: 140, // Fixed width
              child: TextField(
                controller: _whatController,
                readOnly: true,
                onTap: () {
                  _showServicePopup(context);
                },
                decoration: InputDecoration(
                  hintText: 'Services', // Hint text for services
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none, // No border or underline
                  isDense: true, // Reduce height
                  contentPadding: EdgeInsets.symmetric(vertical: 8), // Adjust padding
                ),
              ),
            ),
            VerticalDivider(color: Colors.grey),
            Icon(Icons.location_on, color: Colors.grey, size: 18), // Smaller icon
            SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _whereController,
                decoration: InputDecoration(
                  hintText: 'City', // Hint text for city
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(width: 6),
            Container(
              width: 30, // Set fixed width
              height: 30, // Set fixed height
              padding: EdgeInsets.all(4), // Adjusted padding
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(4), // Smaller background radius
              ),
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.white, size: 20), // Smaller search icon
                onPressed: _searchService,
                padding: EdgeInsets.zero, // Remove extra padding
                constraints: BoxConstraints(), // Remove default constraints
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildServiceCard(Map<String, dynamic> service) {
    ValueNotifier<bool> isFavorite = ValueNotifier<bool>(false); // Track favorite state

    // Function to fetch favorite status
    Future<void> fetchFavoriteStatus(String userId, String providerId) async {
      final url = Uri.parse("https://1stepdev.vercel.app/server/favorite/favoriteStatus/$userId?providerId=$providerId");
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

        final response = await http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
          },
        );


        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          isFavorite.value = responseData["isFavorite"] ?? false;
        } else {
          print("Failed to fetch favorite status");
        }
      } catch (e) {
        print("Error: $e");
      }
    }

    // Function to toggle favorite status
    Future<void> toggleFavorite(String userId, String providerId) async {
      final url = Uri.parse("https://1stepdev.vercel.app/server/favorite/favorites/$userId");

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


        final response = await http.post(
          url,
          body: jsonEncode({"providerId": providerId}),
          headers: {
            "Content-Type": "application/json",
            if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,

          },
        );


        if (response.statusCode == 200) {
          isFavorite.value = !isFavorite.value; // Toggle favorite state
        } else {
          print("Failed to update favorite");
        }
      } catch (e) {
        print("Error: $e");
      }
    }

    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          SharedPreferences prefs = snapshot.data as SharedPreferences;
          String? userId = prefs.getString("user_id");

          if (userId != null) {
            fetchFavoriteStatus(userId, service["id"]);
          }
        }

        return ValueListenableBuilder<bool>(
          valueListenable: isFavorite,
          builder: (context, fav, _) {
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
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                service["service"],
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            String? userId = prefs.getString("user_id");

                            if (userId != null) {
                              toggleFavorite(userId, service["id"]);
                            }
                          },
                          child: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            color: fav ? Colors.red : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // 📍 Location
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primaryColor, size: 16),
                        SizedBox(width: 5),
                        Expanded(child: Text(service["location"], style: TextStyle(fontSize: 12))),
                      ],
                    ),
                    SizedBox(height: 5),

                    // 🎓 Experience
                    Row(
                      children: [
                        Icon(Icons.school, color: AppColors.primaryColor, size: 16),
                        SizedBox(width: 5),
                        Text(service["experience"], style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 5),

                    // 🖥️ Availability
                    Row(
                      children: [
                        Icon(Icons.video_call, color: AppColors.primaryColor, size: 16),
                        SizedBox(width: 5),
                        Text(service["availability"], style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    SizedBox(height: 5),

                    // ⭐ Reviews
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

                    // Price & View Profile Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service["price"],
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryColor),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorProfilePage(
                                  providerId: service["id"],
                                ),
                              ),
                            );
                          },
                          child: Text("View Profile", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  OverlayEntry? _overlayEntry;

  String? _selectedService; // Add this at the top of your class

  void _showServicePopup(BuildContext context) {
    final overlay = Overlay.of(context);
    final renderBox = _searchBoxKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return; // Prevent crash if the widget is not found

    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry?.remove(); // Remove any existing overlay before adding a new one

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + renderBox.size.height + 7,
        width: renderBox.size.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: services.map((service) {
                        return ListTile(
                          title: Text(
                            service["label"],
                            style: TextStyle(
                              color: _selectedService == service["value"] ? AppColors.primaryColor : Colors.black, // Change color if selected
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedService = service["value"]; // Store selected item
                              _whatController.text = service["value"];
                            });
                            _overlayEntry?.remove(); // Close the overlay
                            _overlayEntry = null;
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  /// Call this method when navigating away or disposing the screen
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Override dispose method if using StatefulWidget
  @override
  void dispose() {
    _removeOverlay(); // Ensure overlay is removed when the screen is destroyed
    super.dispose();
  }


}
