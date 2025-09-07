import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 2) // Different typeId from TutionClass and Payment
class StudySession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subject;

  @HiveField(2)
  final DateTime startTime;

  @HiveField(3)
  final DateTime endTime;

  @HiveField(4)
  final int durationMinutes;

  @HiveField(5)
  final String sessionType; // 'timer' or 'manual'

  @HiveField(6)
  final String? notes;

  @HiveField(7)
  final DateTime createdDate;

  StudySession({
    required this.id,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.sessionType,
    this.notes,
    required this.createdDate,
  });

  // Create a copy with updated fields
  StudySession copyWith({
    String? id,
    String? subject,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? sessionType,
    String? notes,
    DateTime? createdDate,
  }) {
    return StudySession(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sessionType: sessionType ?? this.sessionType,
      notes: notes ?? this.notes,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  // Get formatted duration
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get duration in hours (decimal)
  double get durationHours => durationMinutes / 60.0;

  // Check if session is from today
  bool get isToday {
    final now = DateTime.now();
    final sessionDate = createdDate;
    return now.year == sessionDate.year &&
           now.month == sessionDate.month &&
           now.day == sessionDate.day;
  }

  // Check if session is from this week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return createdDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           createdDate.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject': subject,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'durationMinutes': durationMinutes,
      'sessionType': sessionType,
      'notes': notes,
      'createdDate': createdDate.millisecondsSinceEpoch,
    };
  }

  // Create from Map for Firebase
  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] ?? '',
      subject: map['subject'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? DateTime.now().millisecondsSinceEpoch),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? DateTime.now().millisecondsSinceEpoch),
      durationMinutes: map['durationMinutes'] ?? 0,
      sessionType: map['sessionType'] ?? 'manual',
      notes: map['notes'],
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}