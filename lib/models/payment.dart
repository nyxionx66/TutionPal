class Payment {
  final String id;
  final String classId;
  final String subject;
  final String teacher;
  final double amount;
  final DateTime paymentDate;
  final bool isPaid;

  Payment({
    required this.id,
    required this.classId,
    required this.subject,
    required this.teacher,
    required this.amount,
    required this.paymentDate,
    required this.isPaid,
  });
}