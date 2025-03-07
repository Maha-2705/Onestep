import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../AppColors.dart';
import '../Socket/SocketService.dart';

class MessagesPage extends StatefulWidget {
  final String currentUserId;
  final String providerId;

  MessagesPage({required this.currentUserId, required this.providerId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<MessagesPage> {
  TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket?.on("receiveMessage", (data) {
      setState(() {
        messages.add({
          "sender": data["sender"],
          "message": data["message"],
          "createdAt": DateTime.now(),
        });
      });
    });

    loadOldMessages();
  }

  void sendMessage() {
    if (_messageController.text.isEmpty) return;
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.sendMessage(
      "${widget.currentUserId}_${widget.providerId}",
      _messageController.text,
      widget.currentUserId,
      widget.providerId
    );

    setState(() {
      messages.add({
        "sender": widget.currentUserId,
        "message": _messageController.text,
        "createdAt": DateTime.now(),
      });
    });

    _messageController.clear();
  }

  Future<void> loadOldMessages() async {
    if (widget.currentUserId == null || widget.currentUserId!.isEmpty) {
      print("Error: currentUserId is null or empty!");
      return; // Stop execution if currentUserId is null
    }
    final url = "https://1steptest.vercel.app/server/message/getprovider/${widget.currentUserId}";
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('access_token');
    String? Id = prefs.getString('user_id');
    String? googleToken = prefs.getString('google_access_token');

    String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }
      try{
        print("Making GET request to: $url");

        final res = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,

        // Add authentication header if required
        // "Authorization": "Bearer YOUR_ACCESS_TOKEN"
      },
    );

      print("Response Status Code: ${res.statusCode}");
      print("Raw Response Body: ${res.body}");

      if (res.statusCode == 200) {
        final List<dynamic> oldMessages = jsonDecode(res.body);

        setState(() {
          messages.insertAll(0, oldMessages.map((msg) => {
            "sender": msg["sender"],
            "message": msg["message"],
            "createdAt": DateTime.tryParse(msg["createdAt"]) ?? DateTime.now(),
          }).toList());
        });
      } else {
        print("Failed to load messages: ${res.statusCode}");
        print("Response Body: ${res.body}"); // Print response for debugging
      }
    } catch (e) {
      print("Error fetching messages: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // White back arrow
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage("Assets/Images/profile.jpg"), // Replace with user image
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Floyd", style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white70)),
                Text("Online", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          Icon(Icons.call, color: Colors.white),
          SizedBox(width: 30),

        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isMe = message["sender"] == widget.currentUserId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
                        bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      message["message"]!,
                      style: TextStyle(color: isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Icon(Icons.add_circle, color: AppColors.primaryColor, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.mic, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

