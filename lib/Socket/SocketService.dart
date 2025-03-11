import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService with ChangeNotifier {
  IO.Socket? socket;
  String? userId;
  Map<String, bool> onlineStatus = {};

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

    // Listen for new messages
    socket?.on("receiveMessage", (data) {
      print("New Message: $data");
      notifyListeners();
    });
  }

  // Emit message read event
  void handleMessageRead(String messageId) {
    socket?.emit("messageRead", messageId);
  }

  // Send message to the server
  void sendMessage(String roomId, String message, String senderId, String receiverId) {
    socket?.emit("joinRoom", {
      "roomId": roomId,
      "sender": senderId,
      "reciever": receiverId,
    });

    socket?.emit("sendMessage", {
      "roomId": roomId,
      "message": message,
      "sender": senderId,
      "provider": receiverId,
      "userid": senderId,
      "reciever": receiverId,
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
