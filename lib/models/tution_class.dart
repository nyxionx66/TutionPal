import 'package:hive/hive.dart';

// මේ line එක error එකක් පෙන්නුවට අවුලක් ගන්න එපා. 
// උඩ තියෙන command එක run කරාම මේක හරියනවා.
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

  TutionClass({
    required this.subject,
    required this.teacher,
    required this.location,
    required this.day,
    required this.startTime,
    required this.durationHours,
    required this.monthlyFee,
  });
}