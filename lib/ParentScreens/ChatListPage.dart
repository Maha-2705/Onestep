import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ParentScreens/messages_page.dart';
import '../Socket/SocketService.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<Map<String, dynamic>> messages = [];
  Map<String, bool> onlineStatus = {}; // Store online/offline status

  late SocketService socketService;

  @override
  void initState() {
    super.initState();
    socketService = SocketService();
    loadOldMessages();
    socketService.connect(""); // Connect socket

    // Listen for user online
    socketService.socket?.on("UserOnline", (data) {
      String userId = data["userId"];
      setState(() {
        onlineStatus[userId] = true;
      });
    });

    // Listen for user offline
    socketService.socket?.on("UserOut", (data) {
      String userId = data["userId"];
      setState(() {
        onlineStatus[userId] = false;
      });
    });
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
            Uri.parse(
                "https://1steptest.vercel.app/server/message/getlastmessage/$roomID"),
            headers: headers,
          );

          String lastMessage = "No message yet";
          String formattedTime = "";

          if (lastMessageRes.statusCode == 200) {
            final lastMessageData = jsonDecode(lastMessageRes.body);
            lastMessage = lastMessageData["message"] ?? "No message yet";
            String createdAt = lastMessageData["createdAt"] ?? "";
            formattedTime = _formatTime(createdAt);
          }

          // Fetch unread messages count
          final unreadCountRes = await http.get(
            Uri.parse(
                "https://1steptest.vercel.app/server/message/getunreadmessagescount/$roomID?reciever=$userId"),
            headers: headers,
          );

          int unreadCount = 0;
          if (unreadCountRes.statusCode == 200) {
            final unreadData = jsonDecode(unreadCountRes.body);
            unreadCount = unreadData["unreadCount"] ?? 0;
          }

          // *Add provider details to the list*
          updatedMessages.add({
            "id": providerId,
            "fullName": fullName,
            "profilePicture": profilePicture,
            "lastMessage": lastMessage,
            "unreadCount": unreadCount,
            "time": formattedTime,
          });

          socketService.socket?.emit("checkUserStatus", {
            "userId": providerId
          });
          print("Emit checkUserStatus event for providerId: $providerId");
        }

          setState(() {
          messages = updatedMessages;
        });
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }

  String _formatTime(String timestamp) {
    if (timestamp.isEmpty) return "";
    try {
      DateTime parsedTime = DateTime.parse(timestamp).toLocal();
      return DateFormat('hh:mm a').format(parsedTime);
    } catch (e) {
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
          Expanded(
            child: messages.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final user = messages[index];
                bool isOnline = onlineStatus[user["id"]] ?? false;

                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: user["profilePicture"].isNotEmpty
                            ? NetworkImage(user["profilePicture"])
                            : AssetImage("assets/default_profile.png") as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 5,
                          backgroundColor: isOnline ? Colors.green : Colors.grey,
                        ),
                      )
                    ],
                  ),
                  title: Text(user["fullName"], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user["lastMessage"], maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(user["time"], style: TextStyle(fontSize: 12, color: Colors.grey)),
                      if (user["unreadCount"] > 0)
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Text(
                            user["unreadCount"].toString(),
                            style: TextStyle(color: Colors.white, fontSize: 12),
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
    );
  }
}