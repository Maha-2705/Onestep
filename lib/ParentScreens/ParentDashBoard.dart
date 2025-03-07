import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../AppColors.dart';
import '../Socket/SocketService.dart';
import 'ChatListPage.dart';
import 'HomePage.dart';
import 'appointments_page.dart';
import 'messages_page.dart';
import 'profile_page.dart';

class ParentDashBoard extends StatefulWidget {
  final String userId;

  ParentDashBoard({required this.userId});

  @override
  _ParentDashBoardState createState() => _ParentDashBoardState();
}

class _ParentDashBoardState extends State<ParentDashBoard> {
  int _currentIndex = 0;
  String? userId;
  SocketService? socketService;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _saveUserId(widget.userId);
    _loadUserId();
  }

  /// Save userId in SharedPreferences
  void _saveUserId(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  /// Load userId from SharedPreferences and initialize pages
  void _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getString('user_id') ?? 'No ID Found';
      if (userId != 'No ID Found') {
        socketService = Provider.of<SocketService>(context, listen: false);
        socketService?.connect(userId!);
      }
      _pages = [
        HomePage(),
        AppointmentsPage(),
        ChatListPage(),
        ProfilePage(),
      ];
    });
  }

  @override
  void dispose() {
    socketService?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.isNotEmpty
          ? _pages[_currentIndex]
          : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.greycolor,
            showUnselectedLabels: false,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.message),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
