import 'package:hive/hive.dart';

part 'tution_class.g.dart';

@HiveType(typeId: 0) // Hive වලට class එක හඳුන්වලා දෙන ID එක
class TutionClass extends HiveObject {
  @HiveField(0)
  final String subject;

  @HiveField(1)
  final String teacher;

  @HiveField(2)
  final String location;

  @HiveField(3)
  final String day;

  @HiveField(4)
  final String startTime;

  @HiveField(5)
  final int durationHours;

  @HiveField(6)
  final double monthlyFee;

  @HiveField(7)
  final DateTime createdDate; // Add creation date to track from when to generate payments

  @HiveField(8)
  final String id; // Add unique ID for better tracking

  TutionClass({
    required this.subject,
    required this.teacher,
    required this.location,
    required this.day,
    required this.startTime,
    required this.durationHours,
    required this.monthlyFee,
    required this.createdDate,
    required this.id,
  });

  // Helper method to get creation month/year
  String get createdMonth => _getMonthName(createdDate.month);
  int get createdYear => createdDate.year;

  String _getMonthName(int monthNumber) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[monthNumber - 1];
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'teacher': teacher,
      'location': location,
      'day': day,
      'startTime': startTime,
      'durationHours': durationHours,
      'monthlyFee': monthlyFee,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  // Create from Map for Firebase
  factory TutionClass.fromMap(Map<String, dynamic> map) {
    return TutionClass(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      location: map['location'] ?? '',
      day: map['day'] ?? '',
      startTime: map['startTime'] ?? '',
      durationHours: map['durationHours'] ?? 1,
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}