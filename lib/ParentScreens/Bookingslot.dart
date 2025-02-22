import 'package:flutter/material.dart';
import 'package:one_step/AppColors.dart';
import 'package:intl/intl.dart';

import 'package:table_calendar/table_calendar.dart';

class BookSlotPage extends StatefulWidget {
  final String providerId;

  BookSlotPage({required this.providerId});
  @override
  _BookSlotPageState createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  TextEditingController patientNameController = TextEditingController();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  bool isSomeoneElse = false;
  int selectedCategory = 0; // 0: Morning, 1: Afternoon, 2: Night
  String? selectedTime;
  void _changeMonth(bool isNext) {
    setState(() {
      _focusedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month + (isNext ? 1 : -1), // Move forward or backward by 1 month
        1,
      );
    });
  }
  Map<int, List<String>> slotTimes = {
    0: [
      '08:00 AM',
      '08:30 AM',
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM'
    ], // Morning slots
    1: [
      '12:00 PM',
      '12:30 PM',
      '01:00 PM',
      '01:30 PM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM'
    ], // Afternoon slots
    2: [
      '06:00 PM',
      '06:30 PM',
      '07:00 PM',
      '07:30 PM',
      '08:00 PM',
      '08:30 PM',
      '09:00 PM',
      '09:30 PM'
    ] // Night slots
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Get Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Arrow - Previous Month
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    onPressed: () => _changeMonth(false),
                  ),

                  // Display Month & Year
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDay), // Example: "February 2025"
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Right Arrow - Next Month
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios),
                    onPressed: () => _changeMonth(true),
                  ),
                ],
              ),
            ),

            // Calendar Widget
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerVisible: false, // Hide default header

              calendarBuilders: CalendarBuilders(
                dowBuilder: (context, day) {
                  final weekDay = DateFormat('E').format(day); // Get weekday name
                  return Center(
                    child: Text(
                      weekDay.toUpperCase(), // Example: MON, TUE
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),

              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.grey.shade200, // No special highlight for today
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primaryColor, // Fill color for selected date
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: Colors.white, // White text for selected date
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                weekendTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Color for weekends
                ),
              ),
              daysOfWeekVisible: true, // Show weekdays above dates
            ),

            SizedBox(height: 20),
            Text('Available Slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildCategorySelector(),
            SizedBox(height: 30),
            _buildTimeSlots(),
            SizedBox(height: 30),

            // Fill the Details Heading
            Text('Fill the Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),

            // Patient Name TextField
            _buildTextField(label: "Patient Name*", hintText: "Enter Patient Name"),
            SizedBox(height: 10),

            // Dropdown for Services
            _buildDropdown(
              label: "How can we help your family?*",
              items: [ 'Diagnostic Evaluation',
                'Occupational Therapy',
                'Dance Movement',
                'Speech Therapy',
                'Counselling',
                'School-Based Service',
                'Music Therapy',
                'Art As Therapy',
                'ABA Therapy',
                'Social Skills Group'],
            ),
            SizedBox(height: 10),

            // Email & Session Type Row
            Row(
              children: [
                Expanded(child: _buildTextField(label: "Email*", hintText: "Enter Email")),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    label: "Session Type*",
                    items: ["In-Clinic", "In-Home","Virtual"],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Notes TextField
            _buildTextField(label: "Note*", hintText: "Enter Notes", maxLines: 3),
            SizedBox(height: 20),

            // Book a Slot Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text("BOOK A SLOT", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Common Function for TextFields
  Widget _buildTextField({required String label, required String hintText, int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200), // Light Grey Border
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200), // Light Grey Border
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor), // Blue Border on Focus
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }

  // Common Function for Dropdowns
  Widget _buildDropdown({required String label, required List<String> items}) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200), // Light Grey Border
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade200), // Light Grey Border
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryColor), // Blue Border on Focus
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (value) {},
    );
  }
  Widget _buildCategorySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _categoryTab('☀️ Morning', 0),
        _categoryTab('🌟 Afternoon', 1),
        _categoryTab('🌙 Night', 2),
      ],
    );
  }

  Widget _categoryTab(String text, int index) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedCategory = index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: selectedCategory == index ? AppColors.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: TextStyle(color: selectedCategory == index ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: slotTimes[selectedCategory]!.map((time) {
        bool isSelected = selectedTime == time;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTime = time;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(time, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
          ),
        );
      }).toList(),
    );
  }
}
