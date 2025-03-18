import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../AppColors.dart';
import '../Bookings/ProviderProfile.dart';


class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDate = DateTime.now();
  List<Map<String, String>> upcomingAppointments = [
  ];

  List<Map<String, String>> completedAppointments = [
  ];

  List<Map<String, String>> canceledAppointments = [
  ];
  List<Map<String, String>> allAppointments = [];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAppointments();
  }
  void fetchAppointments() async {
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
        Uri.parse("https://1steptest.vercel.app/server/booking/getuserbookings/$Id"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      );


      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);
        List<dynamic> userBookings = jsonResponse["userBookings"];

        setState(() {
          allAppointments.clear();
        });

        for (var booking in userBookings) {
          String status = booking["status"] ?? "pending";
          String doctor = booking["providerDetails"]["fullName"] ?? "Unknown Doctor";
          List<dynamic> serviceList = booking["service"] ?? [];
          String specialty = serviceList.isNotEmpty ? serviceList.join(", ") : "General";

          // Convert API date to yyyy-MM-dd format
          String apiDate = booking["scheduledTime"]["date"] ?? "";
          DateTime parsedDate = DateTime.parse(apiDate);
          String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

          String time = booking["scheduledTime"]["slot"] ?? "N/A";
          String location = booking["providerDetails"]["address"]["city"] ?? "Unknown Location";
          String profilePicture = booking["providerDetails"]["profilePicture"] ?? "";
          String providerId = booking["providerDetails"]["_id"] ?? "Unknown ID";

          Map<String, String> appointment = {
            "doctor": doctor,
            "specialty": specialty,
            "date": formattedDate,  // ✅ Store in yyyy-MM-dd format
            "time": time,
            "location": location,
            "profilePicture": profilePicture,
            "providerId": providerId,
            "status": status,
          };

          setState(() {
            allAppointments.add(appointment);
          });
        }


        filterAppointmentsByDate(_selectedDate);
      } else {
        print("❌ Failed to fetch appointments: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching appointments: $e");
    }
  }

// Function to filter appointments based on the selected date
  void filterAppointmentsByDate(DateTime selectedDate) {
    String formattedSelectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Selected Date: $formattedSelectedDate");

    setState(() {
      // Clear lists before filtering
      upcomingAppointments.clear();
      completedAppointments.clear();
      canceledAppointments.clear();

      for (var appointment in allAppointments) {
        if (appointment["date"] == formattedSelectedDate) {
          if (appointment["status"] == "pending") {
            upcomingAppointments.add(appointment);
          } else if (appointment["status"] == "completed") {
            completedAppointments.add(appointment);
          } else if (appointment["status"] == "rejected") {
            canceledAppointments.add(appointment);
          }
        }
      }
    });

    // Debugging
    print("Upcoming: ${upcomingAppointments.length}");
    print("Completed: ${completedAppointments.length}");
    print("Canceled: ${canceledAppointments.length}");
  }

// Function to format the date with year
  String formatDate(String dateStr) {
    DateTime date = DateTime.parse(dateStr);
    return DateFormat('EEE, MMM d, yyyy').format(
        date); // Example: "Tue, Feb 25, 2025"
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("My Appointments", style: TextStyle(fontWeight: FontWeight
            .bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCalendarView(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList(upcomingAppointments, "Upcoming"),
                // Upcoming Appointments
                _buildAppointmentList(completedAppointments, "Completed"),
                // Completed Appointments
                _buildAppointmentList(canceledAppointments, "Canceled"),
                // Canceled Appointments
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCalendarView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TableCalendar(
        focusedDay: _focusedDate,
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
            _focusedDate = focusedDay;
          });
          filterAppointmentsByDate(selectedDay); // Update appointments based on selected date
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekendStyle: TextStyle(
            color: Colors.red, // Saturday and Sunday text in red
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.grey[200], // Grey background for today
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Colors.black, // Black text color for today
            fontWeight: FontWeight.bold,
          ),
          outsideDaysVisible: false,
        ),
      ),
    );
  }


  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.tab, // Full width indicator
        indicator: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        tabs: [
          Container(
            height: 35, // Increase the height as needed
            alignment: Alignment.center,
            child: Text(
              "Upcoming",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            height: 35,
            alignment: Alignment.center,
            child: Text(
              "Completed",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            height: 35,
            alignment: Alignment.center,
            child: Text(
              "Canceled",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAppointmentList(List<Map<String, String>> appointments, String status) {
    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 1)), // 2-second delay
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()); // Show loading indicator
        }

        if (appointments.isEmpty) {
          return Center(child: Text("No Appointments")); // Show message if no appointments
        }

        IconData statusIcon;
        Color statusColor;

        // Set the icon and color based on status
        if (status == "Upcoming") {
          statusIcon = Icons.access_time; // Clock icon for upcoming
          statusColor = Colors.orangeAccent;
        } else if (status == "Completed") {
          statusIcon = Icons.check_circle; // Checkmark icon for completed
          statusColor = Colors.green;
        } else {
          statusIcon = Icons.cancel; // Cancel icon for canceled
          statusColor = Colors.red;
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            return _buildAppointmentCard(
              doctor: appointments[index]["doctor"] ?? "Unknown",
              providerId: appointments[index]["providerId"] ?? "",
              specialty: appointments[index]["specialty"] ?? "Unknown",
              date: appointments[index]["date"] ?? "Unknown",
              time: appointments[index]["time"] ?? "Unknown",
              location: appointments[index]["location"] ?? "Not specified",
              profilePicture: appointments[index]["profilePicture"] ?? "Not specified",
              statusIcon: statusIcon,
              statusColor: statusColor,
              status: status, // Passing status text (Pending, Completed, Canceled)
            );
          },
        );
      },
    );
  }


  Widget _buildAppointmentCard({
    required String? doctor,
    required String? specialty,
    required String? date,
    required String? time,
    required String? location,
    required IconData? statusIcon,
    required Color? statusColor,
    required String? profilePicture,
    required String? status,
    required String? providerId,
  }) {
    // Check if any required data is null or empty
    bool isLoading = doctor == null || specialty == null || date == null ||
        time == null ||
        location == null || statusIcon == null || statusColor == null ||
        profilePicture == null || status == null || providerId == null;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorProfilePage(providerId: providerId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time (Left Side)
            Padding(
              padding: const EdgeInsets.only(top: 18, right: 8),
              child: Text(
                time!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Right Side Box with Details
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[200]!, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 1,
                      spreadRadius: 1,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Info Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: profilePicture!.isNotEmpty
                                ? NetworkImage(profilePicture) as ImageProvider
                                : AssetImage("Assets/Images/doctor.jpg"),
                          ),
                          SizedBox(width: 15),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                specialty!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                              SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14,
                                      color: AppColors.primaryColor),
                                  SizedBox(width: 3),
                                  Text(
                                    location!.isNotEmpty ? location : "Chennai",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      // Date and Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.calendar_today, color: Colors.black54,
                                    size: 14),
                                SizedBox(width: 5),
                                Text(date!, style: TextStyle(
                                    fontSize: 12, color: Colors.black)),
                              ],
                            ),
                          ),
                          // Status Icon and Text
                          Row(
                            children: [
                              Icon(statusIcon, color: statusColor, size: 16),
                              SizedBox(width: 3),
                              Text(
                                status!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}