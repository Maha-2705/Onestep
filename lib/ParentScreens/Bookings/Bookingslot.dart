import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:one_step/AppColors.dart';

class BookSlotPage extends StatefulWidget {
  final String providerId;

  BookSlotPage({required this.providerId});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookSlotPage> {
  // Controllers for text fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  // Controllers for dropdowns
  String? selectedService;
  String? selectedSessionType;
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();
  int selectedTabIndex = 1; // Default selected tab (Afternoon)
  int selectedTimeIndex = -1; // No time slot selected initially
  Map<String, dynamic>? providerDetails;
  bool isLoading = true;
  List<String> tabs = ["☀ Morning", "🌞 Afternoon", "🌙 Evening"];


  List<DateTime> getDatesForMonth(DateTime currentMonth) {
    List<DateTime> days = [];
    int daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }
    return days;
  }
  @override
  void initState() {
    super.initState();
    fetchProviderDetails();
    selectedDay = DateTime.now(); // Initialize with the current date
    print("Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDay!)}");
    print("Selected Day: ${DateFormat('EEEE').format(selectedDay!)}");
  }

  Future<void> sendRequest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? patientId = prefs.getString('user_id');
    String? token = prefs.getString('access_token');
    String? googleToken = prefs.getString('google_access_token');

    try {
      String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }
      String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate!);

      // ✅ Prevent errors if no time slot is selected
      String selectedSlotTime = (selectedTimeIndex >= 0 && selectedTimeIndex < slots.length)
          ? slots[selectedTimeIndex]
          : "";

      // Request Data
      Map<String, dynamic> requestData = {
        "patient": patientId,
        "provider": widget.providerId,
        "patientName": nameController.text,
        "scheduledTime": {
          "slot": selectedSlotTime, // ✅ Store the actual time slot value
          "date": formattedDate,
        },
        "email": emailController.text,
        "note": noteController.text,
        "service": selectedService,
        "sessionType": selectedSessionType,
        "status": "pending",
      };

      final response = await http.post(
        Uri.parse("https://1steptest.vercel.app/server/booking/bookings"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Successfully Booked: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Successfully Booked...")),
        );
      } else {
        print("Failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (e is TimeoutException) {
        print("⏳ Request timed out! Please check your network.");
      } else {
        print("❌ Error fetching provider details: $e");
      }
    }
  }


  Future<void> fetchProviderDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    String? googleToken = prefs.getString('google_access_token');

    try {
      String cookieHeader = "";
      if (token != null && token.isNotEmpty) {
        cookieHeader += "access_token=$token;";
      }
      if (googleToken != null && googleToken.isNotEmpty) {
        cookieHeader += "google_access_token=$googleToken;";
      }

      var response = await http
          .get(
        Uri.parse("https://1steptest.vercel.app/server/provider/get/${widget
            .providerId}"),
        headers: {
          "Content-Type": "application/json",
          if (cookieHeader.isNotEmpty) "Cookie": cookieHeader,
        },
      )
          .timeout(Duration(seconds: 10)); // ⏳ Timeout set to 10 seconds

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          providerDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("❌ Failed to fetch provider details: ${response.body}");
      }
    } catch (e) {
      if (e is TimeoutException) {
        print("⏳ Request timed out! Please check your network.");
      } else {
        print("❌ Error fetching provider details: $e");
      }
    }
  }

  DateTime? selectedDay; // Declare local variable


  @override
  Widget build(BuildContext context) {
    List<DateTime> days = getDatesForMonth(selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Book a Slot"),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorInfo(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Select Date",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, size: 18,
                            color: AppColors.primaryColor),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(
                                currentMonth.year, currentMonth.month - 1, 1);
                            selectedDate = currentMonth; // Update selected date
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(currentMonth),
                        style: TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, size: 18,
                            color: AppColors.primaryColor),
                        onPressed: () {
                          setState(() {
                            currentMonth = DateTime(
                                currentMonth.year, currentMonth.month + 1, 1);
                            selectedDate = currentMonth; // Update selected date
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              // Generate a list of dates starting from today for the next 30 days

              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    bool isSelected = selectedDay != null &&
                        selectedDay!.day == days[index].day &&
                        selectedDay!.month == days[index].month &&
                        selectedDay!.year == days[index].year;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          DateTime today = DateTime.now();
                          if (days[index].isBefore(DateTime(today.year, today.month, today.day))) {
                            _showOverdueToast();
                          } else {
                            selectedDay = days[index]; // Store selected date in local variable

                            // Reset selected tab and time index
                            selectedTabIndex = 0; // Default to Morning
                            selectedTimeIndex = -1; // Reset time selection

                            // Update and categorize slots for the selected day
                            _categorizeTimeSlots();

                            // Debugging logs
                            print("Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDay!)}");
                            print("Selected Day: ${DateFormat('EEEE').format(selectedDay!)}");
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('EEE').format(days[index]), // Day Name
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              DateFormat('dd').format(days[index]), // Day Number
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),


              SizedBox(height: 20),
              Divider(height: 30),
              Text(
                "Available Timeslots",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              _buildTabSelector(),
              SizedBox(height: 25),
              _buildTimeSlots(),
              SizedBox(height: 20),
              Divider(height: 30),

              _buildPatientForm(),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  onPressed: () {
                    sendRequest();
                  },
                  child: Text('Book a Slot', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showOverdueToast() {
    Fluttertoast.showToast(
      msg: "Sorry, this date is overdue.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black, // Red background
      textColor: Colors.red,
      fontSize: 16.0,
    );
  }
  Widget _buildDoctorInfo() {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: providerDetails?["profilePicture"] != null
              ? NetworkImage(providerDetails?["profilePicture"]) // Network image
              : AssetImage('') as ImageProvider, // Fallback image
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                providerDetails?["fullName"] ?? "Unknown", // Full Name
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                providerDetails?["name"] is List
                    ? (providerDetails?["name"] as List).join(", ") // Convert list to a string
                    : providerDetails?["name"] ?? "Specialization not available",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
                maxLines: 2, // Allows the text to occupy up to 2 lines
                softWrap: true, // Enables wrapping within the available space
              ),
              SizedBox(height: 5),


              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primaryColor, size: 16),
                  Text(
                    providerDetails?["address"]?["city"] ?? "",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              SizedBox(height: 5),


            ],
          ),
        ),
      ],
    );
  }





  Widget _buildTabSelector() {
    List<String> tabs = ["☀ Morning", "🌞 Afternoon", "🌙 Evening"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTabIndex = index;
              selectedTimeIndex = -1; // Reset selected time slot when changing tabs
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              color: selectedTabIndex == index ? AppColors.primaryColor: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tabs[index],
              style: TextStyle(color: selectedTabIndex == index ? Colors.white : Colors.black),
            ),
          ),
        );
      }),
    );
  }
  Map<String, List<String>> categorizedSlots = {
    "Morning": [],
    "Afternoon": [],
    "Evening": [],
  };

  void _categorizeTimeSlots() {
    if (selectedDay == null) return;

    String selectedDayName = DateFormat('EEEE').format(selectedDay!);

    // Check if 'timeSlots' exists and has data for the selected day
    if (providerDetails?["timeSlots"] != null &&
        providerDetails?["timeSlots"][selectedDayName] != null) {
      List<String> slots = List<String>.from(
          providerDetails?["timeSlots"][selectedDayName] ?? []);

      // Clear previous data
      categorizedSlots["Morning"] = [];
      categorizedSlots["Afternoon"] = [];
      categorizedSlots["Evening"] = [];

      for (String time in slots) {
        DateTime parsedTime = DateFormat("hh:mm a").parse(time);

        if (parsedTime.hour < 12) {
          categorizedSlots["Morning"]!.add(time);
        } else if (parsedTime.hour < 18) {
          categorizedSlots["Afternoon"]!.add(time);
        } else {
          categorizedSlots["Evening"]!.add(time);
        }
      }
    }
  }
  List<String> slots = [];

  Widget _buildTimeSlots() {
    String timeCategory = tabs[selectedTabIndex].split(" ")[1]; // Extract Morning, Afternoon, or Evening
    slots = categorizedSlots[timeCategory] ?? []; // ✅ Update class-level slots variable

    if (slots.isEmpty) {
      return Center(
        child: Text(
          "No slots available",
          style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(slots.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTimeIndex = index;
            });
          },
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selectedTimeIndex == index ? Color(0xFFE2D7EA) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              slots[index],
              style: TextStyle(color: selectedTimeIndex == index ? AppColors.primaryColor : Colors.black),
            ),
          ),
        );
      }),
    );
  }


  Widget _buildPatientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField("Patient’s Name", nameController),
        _buildDropdownField("Services", [
          'Diagnostic Evaluation',
          'Occupational Therapy',
          'Dance Movement',
          'Speech Therapy',
          'Counselling',
          'School-Based Service',
          'Music Therapy',
          'Art As Therapy',
          'ABA Therapy',
          'Social Skills Group'
        ], selectedService, (newValue) {
          setState(() {
            selectedService = newValue;
          });
        }),
        Row(
          children: [
            Expanded(child: _buildTextField("Email", emailController)),
            SizedBox(width: 10),
            Expanded(
              child: _buildDropdownField("Session Type", [
                "Virtual",
                "In Home",
                "In Clinic"
              ], selectedSessionType, (newValue) {
                setState(() {
                  selectedSessionType = newValue;
                });
              }),
            ),
          ],
        ),
        _buildTextField("Note", noteController, maxLines: 3),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> options, String? selectedValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            hint: Text("Select $label"),
            value: selectedValue,
            isExpanded: true,
            menuMaxHeight: 200,
            alignment: Alignment.centerLeft,
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: EdgeInsets.only(top: 0),
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(height: 5),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        SizedBox(height: 5),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Enter $label",
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}