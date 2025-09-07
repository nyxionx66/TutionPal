import 'package:hive/hive.dart';

part 'payment.g.dart';

@HiveType(typeId: 1) // Different typeId from TutionClass
class Payment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String classId;

  @HiveField(2)
  final String subject;

  @HiveField(3)
  final String teacher;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final DateTime paymentDate;

  @HiveField(6)
  final bool isPaid;

  @HiveField(7)
  final String month; // Store the month this payment is for

  @HiveField(8)
  final int year; // Store the year this payment is for

  @HiveField(9)
  final DateTime dueDate; // When this payment was due

  Payment({
    required this.id,
    required this.classId,
    required this.subject,
    required this.teacher,
    required this.amount,
    required this.paymentDate,
    required this.isPaid,
    required this.month,
    required this.year,
    required this.dueDate,
  });

  // Create a copy with updated fields
  Payment copyWith({
    String? id,
    String? classId,
    String? subject,
    String? teacher,
    double? amount,
    DateTime? paymentDate,
    bool? isPaid,
    String? month,
    int? year,
    DateTime? dueDate,
  }) {
    return Payment(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      isPaid: isPaid ?? this.isPaid,
      month: month ?? this.month,
      year: year ?? this.year,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  // Check if payment is overdue
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);

  // Get display status
  String get status {
    if (isPaid) return 'Paid';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'subject': subject,
      'teacher': teacher,
      'amount': amount,
      'paymentDate': paymentDate.millisecondsSinceEpoch,
      'isPaid': isPaid,
      'month': month,
      'year': year,
      'dueDate': dueDate.millisecondsSinceEpoch,
    };
  }

  // Create from Map for Firebase
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      paymentDate: DateTime.fromMillisecondsSinceEpoch(map['paymentDate'] ?? DateTime.now().millisecondsSinceEpoch),
      isPaid: map['isPaid'] ?? false,
      month: map['month'] ?? '',
      year: map['year'] ?? DateTime.now().year,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }
}