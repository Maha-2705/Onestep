import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService with ChangeNotifier {
  IO.Socket? socket;
  String? userId;
  Map<String, bool> onlineStatus = {};
  Function(Map<String, dynamic>)? _onMessageReceived;

  void connect(String userId) {
    this.userId = userId;

    socket = IO.io('https://onestepdev.onrender.com', <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
      "withCredentials": true,
    });

    socket?.connect();

    // Emit when user goes online
    socket?.onConnect((_) {
      print("Connected to WebSocket");
      socket?.emit("Online", userId);
    });

    // Emit when user goes offline
    socket?.onDisconnect((_) {
      print("Disconnected from WebSocket");
    });

    // Listen for online users
    socket?.on("UserOnline", (data) {
      String onlineUserId = data['userId'];
      onlineStatus[onlineUserId] = true;
      notifyListeners();
    });

    // Listen for offline users
    socket?.on("UserOut", (data) {
      String offlineUserId = data['userId'];
      onlineStatus[offlineUserId] = false;
      notifyListeners();
    });

    // Listen for new messages and trigger callback if set
    // Listen for new messages
    socket?.on("receiveMessage", (data) {
      print("New Message: $data");

      // Ensure only messages from the other user are added
      if (data["sender"] != userId) {
        notifyListeners();
      }
    });
  }


    // Function to set message listener
  void setOnMessageReceived(Function(Map<String, dynamic>) callback) {
    _onMessageReceived = callback;
  }

  // Emit message read event
  void handleMessageRead(String messageId) {
    socket?.emit("messageRead", messageId);
  }

  // Send message to the server
  void sendMessage(String roomId, String message, String senderId, String receiverId, String userRef) {
    socket?.emit("joinRoom", {
      "roomId": roomId,
      "sender": senderId,
      "provider": receiverId,
      "reciever": userRef,
    });

    socket?.emit("sendMessage", {
      "roomId": roomId,
      "message": message,
      "sender": senderId,
      "provider": receiverId,
      "userid": senderId,
      "reciever": userRef,
    });
  }

  // Disconnect socket when leaving
  void disconnect() {
    socket?.disconnect();
  }

  // Check if user is online
  bool isUserOnline(String providerId) {
    return onlineStatus[providerId] ?? false;
  }
}
