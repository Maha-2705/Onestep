import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../AppColors.dart';
import '../Socket/SocketService.dart';
import 'package:intl/intl.dart';

class MessagesPage extends StatefulWidget {
  final String currentUserId;
  final String providerId;
  final String profilePicture;
  final String fullName;

  MessagesPage({
    required this.currentUserId,
    required this.providerId,
    required this.profilePicture,
    required this.fullName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<MessagesPage> {
  TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMessages();

    final socketService = Provider.of<SocketService>(context, listen: false);

    //  Listen to incoming messages in real-time
    socketService.socket?.on("receiveMessage", (data) {
      if (data["provider"] == widget.providerId &&
          data["userid"] == widget.currentUserId) {
        //  When you receive a message from another person
        if (mounted) {
          setState(() {
            messages.add({
              "sender": data["sender"],
              "message": data["message"],
              "provider": widget.providerId,
              "userid": widget.currentUserId,
              "createdAt": data["createdAt"],
            });

            // ✅ Sort messages by time (to avoid time clashes)
            messages.sort((a, b) =>
                DateTime.parse(a["createdAt"]).compareTo(DateTime.parse(b["createdAt"])));
          });
        }
      }
    });
  }

  Future<void> fetchMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? googleToken = prefs.getString('google_access_token');

    String cookieHeader = "";
    if (token != null && token.isNotEmpty) {
      cookieHeader += "access_token=$token; ";
    }
    if (googleToken != null && googleToken.isNotEmpty) {
      cookieHeader += "google_access_token=$googleToken; ";
    }

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Cookie": cookieHeader,
    };

    setState(() {
      isLoading = true;
    });

    String roomID = "${widget.currentUserId}_${widget.providerId}";
    String url =
        "https://1steptest.vercel.app/server/message/getmessage/$roomID";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Sort messages by time ascending
        List<Map<String, dynamic>> sortedMessages =
        List<Map<String, dynamic>>.from(data);
        sortedMessages.sort((a, b) =>
            DateTime.parse(a["createdAt"]).compareTo(DateTime.parse(b["createdAt"])));

        setState(() {
          messages = sortedMessages;
        });

        // Mark unread messages as read
        List<Map<String, dynamic>> unreadMessages = messages.where((msg) =>
        msg["read"] == false && msg["sender"] != widget.currentUserId).toList();

        for (var msg in unreadMessages) {
          await markMessageAsRead(msg["_id"]);
        }
      } else {
        print("Error: Failed to fetch messages.");
      }
    } catch (error) {
      print("Exception Occurred: $error");
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> markMessageAsRead(String messageId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? googleToken = prefs.getString('google_access_token');

    String cookieHeader = "";
    if (token != null && token.isNotEmpty) {
      cookieHeader += "access_token=$token; ";
    }
    if (googleToken != null && googleToken.isNotEmpty) {
      cookieHeader += "google_access_token=$googleToken; ";
    }
    try {
      final response = await http.put(
        Uri.parse("https://1steptest.vercel.app/server/message/markasread/$messageId"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,

        },
      );

      if (response.statusCode == 200) {
        //  Print full backend response
        print(" Message marked as read successfully!");
        print(" Full Backend Response: ${response.body}");

      } else {
        print(" Failed to mark message as read.");
        print(" Status Code: ${response.statusCode}");
        print(" Response: ${response.body}");
      }
    } catch (error) {
      print(" Error marking message as read: $error");
    }
  }


  void sendMessage() {
    if (_messageController.text.isEmpty) return;
    final socketService = Provider.of<SocketService>(context, listen: false);
    String timeStamp = DateTime.now().toIso8601String();

    // Emit the message to the server
    socketService.sendMessage(
      "${widget.currentUserId}_${widget.providerId}",
      _messageController.text,
      widget.currentUserId,
      widget.providerId,
    );

    // Instantly show the message in your chat
    setState(() {
      messages.add({
        "sender": widget.currentUserId,
        "message": _messageController.text,
        "provider": widget.providerId,
        "userid": widget.currentUserId,
        "createdAt": timeStamp,
      });

      //  Sort messages again by time
      messages.sort((a, b) =>
          DateTime.parse(a["createdAt"]).compareTo(DateTime.parse(b["createdAt"])));
    });

    //  Clear text field
    _messageController.clear();
  }



  String formatTime(String time) {
    DateTime dateTime = DateTime.parse(time);
    return DateFormat.jm().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.profilePicture.isNotEmpty
                  ? NetworkImage(widget.profilePicture)
                  : AssetImage("assets/default_profile.png") as ImageProvider,
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.fullName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white70)),
                Text("Online",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              reverse: false,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                bool isMe = message["sender"] == widget.currentUserId;
                String time = formatTime(message["createdAt"]);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryColor : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
                        bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message["message"]!,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16),
                        ),
                        SizedBox(height: 3),
                        Text(
                          time,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background color
                      borderRadius: BorderRadius.circular(30), // Fully rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none, // Removes the underline
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
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