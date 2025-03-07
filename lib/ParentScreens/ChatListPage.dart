import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ParentScreens/messages_page.dart';

class ChatListPage extends StatelessWidget {
  final List<Map<String, dynamic>> users = [
    {
      "id": "1",
      "name": "Leader-nim",
      "lastMessage": "Time is running!",
      "time": "1m",
      "unreadCount": 2,
      "image": "Assets/Images/profile.jpg"
    },
    {
      "id": "2",
      "name": "Se Hun Oh",
      "lastMessage": "Just stop. I'm already late!",
      "time": "3m",
      "unreadCount": 0,
      "image": "Assets/Images/profile.jpg"
    },
    {
      "id": "3",
      "name": "Jong Dae Hyung",
      "lastMessage": "Typing...",
      "time": "12m",
      "unreadCount": 1,
      "image": "Assets/Images/profile.jpg"
    },
    {
      "id": "4",
      "name": "Yixing Gege",
      "lastMessage": "🎙 Voice Message",
      "time": "15m",
      "unreadCount": 1,
      "image": "Assets/Images/profile.jpg"
    },
    {
      "id": "5",
      "name": "Yeollie Hyung",
      "lastMessage": "I'll send the rest later",
      "time": "30m",
      "unreadCount": 0,
      "image": "Assets/Images/profile.jpg"
    },
  ]; // Example users

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
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(user["image"]),
                  ),
                  title: Text(user["name"],
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(user["lastMessage"],
                      style: TextStyle(
                          color: user["lastMessage"] == "Typing..."
                              ? Colors.blue
                              : Colors.grey[700])),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user["time"], style: TextStyle(color: Colors.grey)),
                      if (user["unreadCount"] > 0)
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            user["unreadCount"].toString(),
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    // Fetch the user_id from SharedPreferences before navigating
                    final prefs = await SharedPreferences.getInstance();
                    final currentUserId = prefs.getString("user_id") ?? "";

                    if (currentUserId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesPage(
                            currentUserId: currentUserId,
                            providerId: user["id"],
                          ),
                        ),
                      );
                    } else {
                      print("User ID not found in SharedPreferences");
                      // You can show an alert here if needed
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
        onPressed: () {},
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
