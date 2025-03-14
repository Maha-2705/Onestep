import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:one_step/AppColors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Bookings/ProviderProfile.dart';


class FavouriteListScreen extends StatefulWidget {
  @override
  _FavouriteListScreenState createState() => _FavouriteListScreenState();
}
class _FavouriteListScreenState extends State<FavouriteListScreen> {
  List<dynamic> favouriteList = [];

  @override
  void initState() {
    super.initState();
    fetchFavouritelist();
  }

// 🔥 Fetch Ratings for Each Provider
  void _fetchRatingsForProviders() async {
    for (int i = 0; i < favouriteList.length; i++) {
      String providerId = favouriteList[i]["_id"]; // Correct field name
      try {
        final Uri url = Uri.parse(
            'https://1steptest.vercel.app/server/rating/getreview/$providerId');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          var ratingData = json.decode(response.body);
          setState(() {
            favouriteList[i]["rating"] = ratingData["totalrating"] ?? "N/A";
            favouriteList[i]["reviews"] = ratingData["totalratings"] ?? 0;
          });
        } else {
          print('Failed to fetch ratings for provider $providerId');
        }
      } catch (error) {
        print('Error fetching rating for provider $providerId: $error');
      }
    }
  }


  void fetchFavouritelist() async {
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
        Uri.parse(
            "https://1steptest.vercel.app/server/favorite/favoriteList/$Id"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse["success"] == true &&
            jsonResponse.containsKey("favorites")) {
          setState(() {
            favouriteList = jsonResponse["favorites"];
          });
          _fetchRatingsForProviders();
        }
      }
    } catch (e) {
      print("❌ Error fetching favourite list: $e");
    }
  }

  Future<void> toggleFavorite(String userId, String providerId) async {
    final url = Uri.parse(
        "https://1stepdev.vercel.app/server/favorite/favorites/$userId");

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

      print("Toggle Favorite Response: ${response.body}");

      if (response.statusCode == 200) {
        // Remove from the list after unfavorite
        setState(() {
          favouriteList.removeWhere((item) => item["_id"] == providerId);
        });
      } else {
        print("Failed to update favorite");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        title: Text(
          'My Favourites',
          style: TextStyle(color: Colors.white,fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(), // Fetch SharedPreferences
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          SharedPreferences prefs = snapshot.data!;
          String userId = prefs.getString('user_id') ?? "";

          return favouriteList.isEmpty
              ? FutureBuilder(
            future: Future.delayed(Duration(seconds: 1)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else {
                return Center(child: Text("No favorites found"));
              }
            },
          ) : ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: favouriteList.length,
            itemBuilder: (context, index) {
              var item = favouriteList[index];
              String formatServices(List<dynamic> services) {
                if (services.isEmpty) return "";
                if (services.length == 1) return services.first;
                return "${services.first} +${services.length - 1} more";
              }

              String serviceNames = formatServices(
                  item["name"] as List<dynamic>);

              String providerId = item["_id"]; // Provider ID for unfavoriting

              return _buildFavouriteCard(
                userId: userId,
                providerId: providerId,
                imageUrl: item["profilePicture"] ??
                    "https://via.placeholder.com/150",
                name: item["fullName"] ?? "Unknown",
                service: serviceNames,
                location: "${item["address"]["city"]}, ${item["address"]["state"]}",
                experience: "${item["experience"]} years",
                rating: "${item["rating"] ?? "N/A"} (${item["reviews"] ??
                    0} reviews)",

                price: "₹${item["regularPrice"]}",
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavouriteCard({
    required String userId,
    required String providerId,
    required String imageUrl,
    required String name,
    required String service,
    required String location,
    required String experience,
    required String rating,
    required String price,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      // Increased spacing between cards
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorProfilePage(providerId: providerId),
            ),
          );
        },
        child: Card(
          color: Colors.grey[200], // Light grey background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0), // Reduced padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Prevents unnecessary extra height
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(imageUrl),
                      radius: 25,
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            service,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => toggleFavorite(userId, providerId),
                    ),
                  ],
                ),
                SizedBox(height: 8), // Reduced spacing
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16,
                        color: AppColors.primaryColor),
                    SizedBox(width: 6),
                    Text(location, style: TextStyle(fontSize: 14)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.school, size: 16, color: AppColors
                              .primaryColor),
                          SizedBox(width: 6),
                          Text(experience, style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(rating, style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8), // Reduced spacing
                Text(
                  price,
                  style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}