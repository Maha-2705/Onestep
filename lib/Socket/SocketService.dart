import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService with ChangeNotifier {
  IO.Socket? socket;

  void connect(String userId) {
    socket = IO.io('https://onestepdev.onrender.com', <String, dynamic>{
      "transports": ["websocket"],
      "autoConnect": false,
      "withCredentials": true,
    });

    socket?.connect();
    socket?.onConnect((_) {
      print("Connected to WebSocket");
      socket?.emit("Online", userId);
    });

    socket?.onDisconnect((_) {
      print("Disconnected from WebSocket");
    });

    socket?.on("UserOnline", (data) {
      print("User Online: $data");
    });

    socket?.on("UserOut", (data) {
      print("User Offline: $data");
    });

    // Listen for incoming messages
    socket?.on("receiveMessage", (data) {
      print("New message received: $data");
      // Notify listeners or update UI accordingly
      notifyListeners();
    });

    notifyListeners();
  }

  void sendMessage(String roomId, String message, String senderId, String receiverId) {
    if (socket == null) return;

    // Emit "joinRoom" before sending a message
    socket?.emit("joinRoom", {
      "roomId": roomId,
      "sender": senderId,
      "reciever": receiverId,
    });

    // Emit "sendMessage" event
    socket?.emit("sendMessage", {
      "roomId": roomId,
      "message": message,
      "sender": senderId,
      "reciever": receiverId,
    });
  }

  void handleMessageRead(String messageId) {
    socket?.emit("messageRead", messageId);
  }

  void disconnect() {
    socket?.disconnect();
  }
}
