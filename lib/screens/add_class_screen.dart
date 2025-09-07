// add_class_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tution_class.dart';
import '../services/data_service.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final _subjectCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final DataService _dataService = DataService();

  String _selectedDay = "Monday";
  TimeOfDay? _selectedTime;
  double _duration = 1;
  int _selectedIndex = 0; // For bottom navigation

  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    _dataService.initializeHive();
  }

  void _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveClass() async {
    if (_subjectCtrl.text.isEmpty ||
        _teacherCtrl.text.isEmpty ||
        _locationCtrl.text.isEmpty ||
        _selectedTime == null ||
        _feeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final tutionClass = TutionClass(
      subject: _subjectCtrl.text,
      teacher: _teacherCtrl.text,
      location: _locationCtrl.text,
      day: _selectedDay,
      startTime: _selectedTime!.format(context),
      durationHours: _duration.toInt(),
      monthlyFee: double.tryParse(_feeCtrl.text) ?? 0,
    );

    // Save using DataService (offline-first)
    await _dataService.addClass(tutionClass);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Class added successfully! 🎉"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    Navigator.pop(context, tutionClass);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate back to home
      Navigator.pop(context);
    }
    // Other navigation logic can be added here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add a New Class",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF2A66F2),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? const Color(0xFF2A66F2).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
                    size: 24,
                  ),
                ),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? const Color(0xFF2A66F2).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 1 ? Icons.calendar_month : Icons.calendar_month_outlined,
                    size: 24,
                  ),
                ),
                label: "Timetable",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? const Color(0xFF2A66F2).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 2 ? Icons.account_balance_wallet : Icons.account_balance_wallet_outlined,
                    size: 24,
                  ),
                ),
                label: "Fees",
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3
                        ? const Color(0xFF2A66F2).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _selectedIndex == 3 ? Icons.description : Icons.description_outlined,
                    size: 24,
                  ),
                ),
                label: "Papers",
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputField("Subject Name", _subjectCtrl, "e.g. Combined Mathematics"),
              const SizedBox(height: 14),
              _inputField("Teacher's Name", _teacherCtrl, "e.g. Mr. Perera"),
              const SizedBox(height: 14),
              _inputField("Location", _locationCtrl, "e.g. Colombo"),
              const SizedBox(height: 20),

              // Day Picker
              Text("Day", style: _labelStyle()),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _days.map((day) {
                  final selected = _selectedDay == day;
                  return ChoiceChip(
                    label: Text(
                      day,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    selectedColor: const Color(0xFF2A66F2),
                    backgroundColor: const Color(0xFFF1F1F1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Time Picker
              Text("Time", style: _labelStyle()),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A66F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime == null
                      ? "Select Start Time"
                      : _selectedTime!.format(context),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
                const SizedBox(height: 20),

              // Duration Slider
              Text("Duration (hours)", style: _labelStyle()),
              const SizedBox(height: 6),
              Slider(
                value: _duration,
                min: 1,
                max: 12,
                divisions: 11,
                activeColor: const Color(0xFF2A66F2),
                label: "${_duration.toInt()}h",
                onChanged: (val) {
                  setState(() {
                    _duration = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Monthly Fee
              _inputField("Monthly Fee (LKR)", _feeCtrl, "e.g. 2500",
                  inputType: TextInputType.number),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveClass,
                  child: Text(
                    "Save Class",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              
              // Extra space for bottom navigation
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable input field
  Widget _inputField(String label, TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle()),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: inputType,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _labelStyle() {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );
  }
}
