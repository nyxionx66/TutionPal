import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../models/tution_class.dart';

class StudyTimerService {
  static final StudyTimerService _instance = StudyTimerService._internal();
  factory StudyTimerService() => _instance;
  StudyTimerService._internal();

  late Box<StudySession> _studySessionsBox;
  final Uuid _uuid = const Uuid();

  // Timer state
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pauseTime;
  int _elapsedSeconds = 0;
  String? _currentSubject;

  // Stream controllers for UI updates
  final StreamController<int> _timerController = StreamController<int>.broadcast();
  final StreamController<bool> _isRunningController = StreamController<bool>.broadcast();
  final StreamController<bool> _isPausedController = StreamController<bool>.broadcast();

  // Getters for streams
  Stream<int> get timerStream => _timerController.stream;
  Stream<bool> get isRunningStream => _isRunningController.stream;
  Stream<bool> get isPausedStream => _isPausedController.stream;

  // Getters for current state
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  String? get currentSubject => _currentSubject;

  Future<void> initialize() async {
    try {
      _studySessionsBox = Hive.box<StudySession>('study_sessions');
      print('Study timer service initialized');
    } catch (e) {
      print('Error initializing study timer service: $e');
      rethrow;
    }
  }

  void startTimer(String subject) {
    if (_isRunning && _currentSubject == subject) {
      print('Timer already running for this subject');
      return;
    }

    // Stop current timer if running for different subject
    if (_isRunning && _currentSubject != subject) {
      stopTimer();
    }

    _currentSubject = subject;
    _startTime = DateTime.now();
    _isRunning = true;
    _isPaused = false;
    _elapsedSeconds = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _timerController.add(_elapsedSeconds);
    });

    _isRunningController.add(_isRunning);
    _isPausedController.add(_isPaused);

    print('Timer started for subject: $subject');
  }

  void pauseTimer() {
    if (!_isRunning || _isPaused) return;

    _timer?.cancel();
    _pauseTime = DateTime.now();
    _isPaused = true;

    _isPausedController.add(_isPaused);
    print('Timer paused');
  }

  void resumeTimer() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _timerController.add(_elapsedSeconds);
    });

    _isPausedController.add(_isPaused);
    print('Timer resumed');
  }

  Future<void> stopTimer() async {
    if (!_isRunning) return;

    _timer?.cancel();
    
    if (_elapsedSeconds > 0 && _currentSubject != null && _startTime != null) {
      // Save the study session
      await _saveStudySession();
    }

    _resetTimer();
    print('Timer stopped and session saved');
  }

  void _resetTimer() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _elapsedSeconds = 0;
    _currentSubject = null;
    _startTime = null;
    _pauseTime = null;

    _timerController.add(_elapsedSeconds);
    _isRunningController.add(_isRunning);
    _isPausedController.add(_isPaused);
  }

  Future<void> _saveStudySession() async {
    if (_startTime == null || _currentSubject == null) return;

    try {
      final endTime = DateTime.now();
      final durationMinutes = (_elapsedSeconds / 60).round();

      if (durationMinutes < 1) {
        print('Session too short to save (less than 1 minute)');
        return;
      }

      final session = StudySession(
        id: _uuid.v4(),
        subject: _currentSubject!,
        startTime: _startTime!,
        endTime: endTime,
        durationMinutes: durationMinutes,
        sessionType: 'timer',
        createdDate: DateTime.now(),
      );

      await _studySessionsBox.add(session);
      print('Study session saved: ${session.subject} - ${session.formattedDuration}');
    } catch (e) {
      print('Error saving study session: $e');
    }
  }

  Future<void> addManualSession({
    required String subject,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    try {
      final durationMinutes = endTime.difference(startTime).inMinutes;

      if (durationMinutes < 1) {
        throw Exception('Session duration must be at least 1 minute');
      }

      final session = StudySession(
        id: _uuid.v4(),
        subject: subject,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        sessionType: 'manual',
        notes: notes,
        createdDate: DateTime.now(),
      );

      await _studySessionsBox.add(session);
      print('Manual study session added: ${session.subject} - ${session.formattedDuration}');
    } catch (e) {
      print('Error adding manual study session: $e');
      rethrow;
    }
  }

  List<StudySession> getAllSessions() {
    return _studySessionsBox.values.toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
  }

  List<StudySession> getTodaySessions() {
    return getAllSessions().where((session) => session.isToday).toList();
  }

  List<StudySession> getThisWeekSessions() {
    return getAllSessions().where((session) => session.isThisWeek).toList();
  }

  Map<String, List<StudySession>> getSessionsBySubject() {
    final sessions = getAllSessions();
    final Map<String, List<StudySession>> sessionsBySubject = {};

    for (final session in sessions) {
      if (!sessionsBySubject.containsKey(session.subject)) {
        sessionsBySubject[session.subject] = [];
      }
      sessionsBySubject[session.subject]!.add(session);
    }

    return sessionsBySubject;
  }

  Map<String, double> getTodayStatsBySubject() {
    final todaySessions = getTodaySessions();
    final Map<String, double> stats = {};

    for (final session in todaySessions) {
      stats[session.subject] = (stats[session.subject] ?? 0) + session.durationHours;
    }

    return stats;
  }

  Map<String, double> getWeekStatsBySubject() {
    final weekSessions = getThisWeekSessions();
    final Map<String, double> stats = {};

    for (final session in weekSessions) {
      stats[session.subject] = (stats[session.subject] ?? 0) + session.durationHours;
    }

    return stats;
  }

  double getTotalStudyTimeToday() {
    return getTodaySessions().fold(0.0, (sum, session) => sum + session.durationHours);
  }

  double getTotalStudyTimeThisWeek() {
    return getThisWeekSessions().fold(0.0, (sum, session) => sum + session.durationHours);
  }

  int getTotalSessionsToday() {
    return getTodaySessions().length;
  }

  int getTotalSessionsThisWeek() {
    return getThisWeekSessions().length;
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final sessions = _studySessionsBox.values.toList();
      for (int i = 0; i < sessions.length; i++) {
        if (sessions[i].id == sessionId) {
          await _studySessionsBox.deleteAt(i);
          print('Study session deleted: $sessionId');
          break;
        }
      }
    } catch (e) {
      print('Error deleting study session: $e');
      rethrow;
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  void dispose() {
    _timer?.cancel();
    _timerController.close();
    _isRunningController.close();
    _isPausedController.close();
  }
}