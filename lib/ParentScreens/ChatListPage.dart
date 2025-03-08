import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ParentScreens/messages_page.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    loadOldMessages();
  }


  Future<void> loadOldMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? userId = prefs.getString('user_id');
    String? googleToken = prefs.getString('google_access_token');

    if (userId == null) {
      print("User ID not found in SharedPreferences");
      return;
    }

    final url = "https://1steptest.vercel.app/server/message/getprovider/$userId";

    Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    String cookieHeader = "";
    if (token != null && token.isNotEmpty) {
      cookieHeader += "access_token=$token;";
    }
    if (googleToken != null && googleToken.isNotEmpty) {
      cookieHeader += "google_access_token=$googleToken;";
    }

    if (cookieHeader.isNotEmpty) {
      headers["Cookie"] = cookieHeader;
    }

    try {
      final res = await http.get(Uri.parse(url), headers: headers);

      print("Provider API Response Status: ${res.statusCode}");
      print("Provider API Response Body: ${res.body}");

      if (res.statusCode == 200) {
        final List<dynamic> providers = jsonDecode(res.body);
        List<Map<String, dynamic>> updatedMessages = [];

        for (var provider in providers) {
          String providerId = provider["_id"];
          String fullName = provider["fullName"] ?? "Unknown";
          String profilePicture = provider["profilePicture"] ?? "";
          String roomID = "${userId}_$providerId";

          // Fetch last message
          final lastMessageRes = await http.get(
            Uri.parse("https://1steptest.vercel.app/server/message/getlastmessage/$roomID"),
            headers: headers,
          );

          print("Last Message API Response for $roomID - Status: ${lastMessageRes.statusCode}");
          print("Last Message API Response Body: ${lastMessageRes.body}");

          String lastMessage = "No message yet";
          String formattedTime = "";

          if (lastMessageRes.statusCode == 200) {
            final lastMessageData = jsonDecode(lastMessageRes.body);
            lastMessage = lastMessageData["message"] ?? "No message yet";

            // Extract and format the time
            String createdAt = lastMessageData["createdAt"] ?? "";
            formattedTime = _formatTime(createdAt);
          }

          // Fetch unread messages count
          final unreadCountRes = await http.get(
            Uri.parse("https://1steptest.vercel.app/server/message/getunreadmessagescount/$roomID?reciever=$userId"),
            headers: headers,
          );

          print("Unread Messages API Response for $roomID - Status: ${unreadCountRes.statusCode}");
          print("Unread Messages API Response Body: ${unreadCountRes.body}");

          int unreadCount = 0;
          try {
            final unreadData = jsonDecode(unreadCountRes.body);
            if (unreadData is Map && unreadData.containsKey("unreadCount")) {
              unreadCount = unreadData["unreadCount"] is int
                  ? unreadData["unreadCount"]
                  : int.tryParse(unreadData["unreadCount"].toString()) ?? 0;
            } else {
              print(" Unexpected response format for unread messages.");
            }
          } catch (e) {
            print("Error parsing unread messages: $e");
          }

          // **Add provider details to the list**
          updatedMessages.add({
            "id": providerId,
            "fullName": fullName,
            "profilePicture": profilePicture,
            "lastMessage": lastMessage,
            "unreadCount": unreadCount,
            "time": formattedTime,  // Store formatted time
          });
        }

        // **Update the state with the new message list**
        setState(() {
          messages = updatedMessages;
        });
      }
    } catch (e) {
      print(" Error fetching messages: $e");
    }
  }
  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return "";
    try {
      DateTime parsedTime = DateTime.parse(timestamp).toLocal(); // Convert to local time
      return DateFormat('hh:mm a').format(parsedTime); // Example: "10:39 AM"
    } catch (e) {
      print(" Error formatting time: $e");
      return "";
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("All Messages", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(15),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search messages",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Chat List
          Expanded(
            child: messages.isEmpty
                ? Center(child: CircularProgressIndicator()) // Loading Indicator
                : ListView.builder(
              itemCount: messages.length,

              itemBuilder: (context, index) {
                final user = messages[index];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: user["profilePicture"].isNotEmpty
                        ? NetworkImage(user["profilePicture"])
                        : AssetImage("assets/default_profile.png") as ImageProvider,
                  ),
                  title: Text(user["fullName"], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user["lastMessage"], maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(user["time"], style: TextStyle(fontSize: 12, color: Colors.grey)), // Show time
                      if (user["unreadCount"] > 0)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Center(
                            child: Text(
                              user["unreadCount"].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center, // Ensure the text is centered
                            ),
                          ),
                        ),

                    ],
                  ),
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final currentUserId = prefs.getString("user_id") ?? "";

                    if (currentUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPage(
                            currentUserId: currentUserId,
                            providerId: user["id"],
                            profilePicture: user["profilePicture"],
                            fullName: user["fullName"],
                          ),
                        ),
                      );

                    } else {
                      print("User ID not found in SharedPreferences");
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Floating Button for New Chat
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("New Chat");
        },
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}