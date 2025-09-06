// add_class_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/tution_class.dart';

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

  String _selectedDay = "Monday";
  TimeOfDay? _selectedTime;
  double _duration = 1;

  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

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

  void _saveClass() {
    if (_subjectCtrl.text.isEmpty ||
        _teacherCtrl.text.isEmpty ||
        _locationCtrl.text.isEmpty ||
        _selectedTime == null ||
        _feeCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
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

    Navigator.pop(context, tutionClass);
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
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputField("Subject Name", _subjectCtrl, "e.g. Combined Mathematics"),
              const SizedBox(height: 16),
              _inputField("Teacher's Name", _teacherCtrl, "e.g. Mr. Perera"),
              const SizedBox(height: 16),
              _inputField("Location", _locationCtrl, "e.g. Colombo"),
              const SizedBox(height: 24),

              // Day Picker
              Text("Day", style: _labelStyle()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                children: _days.map((day) {
                  final selected = _selectedDay == day;
                  return ChoiceChip(
                    label: Text(
                      day,
                      style: GoogleFonts.poppins(
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
              const SizedBox(height: 24),

              // Time Picker
              Text("Time", style: _labelStyle()),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A66F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _pickTime,
                icon: const Icon(Icons.access_time),
                label: Text(
                  _selectedTime == null
                      ? "Select Start Time"
                      : _selectedTime!.format(context),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),

              // Duration Slider
              Text("Duration (hours)", style: _labelStyle()),
              const SizedBox(height: 8),
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
              const SizedBox(height: 24),

              // Monthly Fee
              _inputField("Monthly Fee (LKR)", _feeCtrl, "e.g. 2500",
                  inputType: TextInputType.number),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveClass,
                  child: Text(
                    "Save Class",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: inputType,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey,
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
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    );
  }
}
