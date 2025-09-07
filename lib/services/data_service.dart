import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/tution_class.dart';
import '../models/payment.dart';
import '../models/study_session.dart';
import 'auth_service.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  // Hive boxes
  late Box<TutionClass> _classesBox;
  late Box<Payment> _paymentsBox;
  late Box<StudySession> _studySessionsBox;
  late Box<Map> _syncQueueBox;

  static const String paymentsBoxName = 'payments';
  static const String studySessionsBoxName = 'study_sessions';
  static const String syncQueueBoxName = 'sync_queue';

  // Debug callback for splash screen
  Function(String)? onDebugMessage;

  void setDebugCallback(Function(String) callback) {
    onDebugMessage = callback;
  }

  void _debug(String message) {
    print('DataService: $message');
    onDebugMessage?.call(message);
  }

  Future<void> initializeHive() async {
    _debug('Initializing Hive databases...');
    try {
      _classesBox = Hive.box<TutionClass>('classes');
      _paymentsBox = Hive.box<Payment>(paymentsBoxName);
      _studySessionsBox = Hive.box<StudySession>(studySessionsBoxName);
      _syncQueueBox = await Hive.openBox<Map>(syncQueueBoxName);
      _debug('Hive databases initialized successfully');
    } catch (e) {
      _debug('Error initializing Hive: $e');
      rethrow;
    }
  }

  Future<bool> hasInternetAccess() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // CLASS OPERATIONS
  Future<void> addClass(TutionClass tutionClass) async {
    _debug('Adding new class: ${tutionClass.subject}');
    await _classesBox.add(tutionClass);
    
    // Generate payments for all months from creation date to current date
    await _generatePaymentsFromCreationDate(tutionClass);
    _debug('Class added successfully with payment history');
  }

  List<TutionClass> getAllClasses() {
    return _classesBox.values.toList();
  }

  Future<void> deleteClass(int index) async {
    final tutionClass = _classesBox.getAt(index);
    if (tutionClass != null) {
      _debug('Deleting class: ${tutionClass.subject}');
      // Delete associated payments
      final payments = getAllPayments();
      for (int i = payments.length - 1; i >= 0; i--) {
        if (payments[i].classId == tutionClass.id) {
          await _paymentsBox.deleteAt(i);
        }
      }
      // Delete the class
      await _classesBox.deleteAt(index);
      _debug('Class and associated payments deleted');
    }
  }

  // PAYMENT OPERATIONS - ENHANCED WITH OVERDUE HANDLING
  Future<void> _generatePaymentsFromCreationDate(TutionClass tutionClass) async {
    final now = DateTime.now();
    final creationDate = tutionClass.createdDate;
    
    _debug('Generating monthly payments starting from ${creationDate.month}/${creationDate.year}');

    // Start from the class creation month and generate up to current month
    DateTime currentMonth = DateTime(creationDate.year, creationDate.month, 1);
    final today = DateTime.now();
    final endMonth = DateTime(today.year, today.month, 1);

    while (currentMonth.isBefore(endMonth) || currentMonth.isAtSameMomentAs(endMonth)) {
      final monthName = _getMonthName(currentMonth.month);
      final year = currentMonth.year;

      // Check if payment already exists for this class and month
      final existingPayments = getAllPayments();
      final existsForMonth = existingPayments.any((payment) =>
          payment.classId == tutionClass.id &&
          payment.month == monthName &&
          payment.year == year);

      if (!existsForMonth) {
        // Payment is due on the last day of the month
        final lastDayOfMonth = DateTime(year, currentMonth.month + 1, 0);
        
        final payment = Payment(
          id: _uuid.v4(),
          classId: tutionClass.id,
          subject: tutionClass.subject,
          teacher: tutionClass.teacher,
          amount: tutionClass.monthlyFee,
          paymentDate: currentMonth, // Will be updated when paid
          isPaid: false,
          month: monthName,
          year: year,
          dueDate: lastDayOfMonth, // Due on last day of month
        );

        await _paymentsBox.add(payment);
        _debug('Generated payment for $monthName $year - Due: ${lastDayOfMonth.day}/${lastDayOfMonth.month}');
      }

      // Move to next month
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    }
  }

  Future<void> generatePaymentsForMonth(String month, int year) async {
    final classes = getAllClasses();
    _debug('Generating payments for $month $year for ${classes.length} classes');
    
    // Only generate payments for current and past months, not future months
    final now = DateTime.now();
    final targetMonth = DateTime(year, _getMonthNumber(month), 1);
    final currentMonth = DateTime(now.year, now.month, 1);
    
    // Don't generate payments for future months
    if (targetMonth.isAfter(currentMonth)) {
      _debug('Skipping payment generation for future month: $month $year');
      return;
    }
    
    for (final tutionClass in classes) {
      // Only generate if the class was created before or during this month
      final classCreationMonth = DateTime(tutionClass.createdDate.year, tutionClass.createdDate.month, 1);
      
      if (classCreationMonth.isBefore(targetMonth) || classCreationMonth.isAtSameMomentAs(targetMonth)) {
        // Check if payment already exists for this class and month
        final existingPayments = getAllPayments();
        final existsForMonth = existingPayments.any((payment) =>
            payment.classId == tutionClass.id &&
            payment.month == month &&
            payment.year == year);

        if (!existsForMonth) {
          // Due on last day of the month
          final lastDayOfMonth = DateTime(year, _getMonthNumber(month) + 1, 0);
          
          final payment = Payment(
            id: _uuid.v4(),
            classId: tutionClass.id,
            subject: tutionClass.subject,
            teacher: tutionClass.teacher,
            amount: tutionClass.monthlyFee,
            paymentDate: DateTime(year, _getMonthNumber(month), 1),
            isPaid: false,
            month: month,
            year: year,
            dueDate: lastDayOfMonth,
          );

          await _paymentsBox.add(payment);
          _debug('Generated payment for ${tutionClass.subject} - $month $year');
        }
      }
    }
  }

  List<Payment> getAllPayments() {
    return _paymentsBox.values.toList();
  }

  List<Payment> getPaymentsForMonth(String month, int year) {
    return _paymentsBox.values
        .where((payment) => payment.month == month && payment.year == year)
        .toList();
  }

  // NEW: Get payments for current month INCLUDING overdue from previous months
  List<Payment> getPaymentsForCurrentView() {
    final now = DateTime.now();
    final currentMonth = _getMonthName(now.month);
    final currentYear = now.year;
    
    // Get current month payments
    final currentMonthPayments = getPaymentsForMonth(currentMonth, currentYear);
    
    // Get all overdue payments from previous months
    final overduePayments = getOverduePayments();
    
    // Combine them, avoiding duplicates
    final allPayments = <Payment>[];
    allPayments.addAll(currentMonthPayments);
    
    for (final overduePayment in overduePayments) {
      // Only add if not already in current month payments
      final isDuplicate = currentMonthPayments.any((p) => p.id == overduePayment.id);
      if (!isDuplicate) {
        allPayments.add(overduePayment);
      }
    }
    
    // Sort by due date (oldest first)
    allPayments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    return allPayments;
  }

  List<Payment> getOverduePayments() {
    final now = DateTime.now();
    return _paymentsBox.values
        .where((payment) => !payment.isPaid && payment.dueDate.isBefore(now))
        .toList();
  }

  // Get current month name dynamically
  String getCurrentMonth() {
    final now = DateTime.now();
    return _getMonthName(now.month);
  }

  int getCurrentYear() {
    return DateTime.now().year;
  }

  // Get real fee progress data
  Map<String, double> getFeeProgress() {
    final payments = getAllPayments();
    final totalFees = payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final paidFees = payments.where((p) => p.isPaid).fold(0.0, (sum, payment) => sum + payment.amount);
    
    return {
      'total': totalFees,
      'paid': paidFees,
      'outstanding': totalFees - paidFees,
      'progress': totalFees > 0 ? paidFees / totalFees : 0.0,
    };
  }

  // Get fee progress for current view (including overdue)
  Map<String, double> getCurrentViewFeeProgress() {
    final payments = getPaymentsForCurrentView();
    final totalFees = payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final paidFees = payments.where((p) => p.isPaid).fold(0.0, (sum, payment) => sum + payment.amount);
    
    return {
      'total': totalFees,
      'paid': paidFees,
      'outstanding': totalFees - paidFees,
      'progress': totalFees > 0 ? paidFees / totalFees : 0.0,
    };
  }

  Future<void> updatePaymentStatus(String paymentId, bool isPaid) async {
    _debug('Updating payment status: $paymentId -> ${isPaid ? "PAID" : "UNPAID"}');
    final payments = _paymentsBox.values.toList();
    for (int i = 0; i < payments.length; i++) {
      if (payments[i].id == paymentId) {
        final updatedPayment = payments[i].copyWith(
          isPaid: isPaid,
          paymentDate: isPaid ? DateTime.now() : payments[i].dueDate,
        );
        await _paymentsBox.putAt(i, updatedPayment);
        _debug('Payment status updated successfully');
        break;
      }
    }
  }

  Future<void> addPayment(Payment payment) async {
    await _paymentsBox.add(payment);
  }

  // FIREBASE SYNC METHODS
  Future<void> syncWithFirebase() async {
    if (!_authService.isLoggedIn || !(await hasInternetAccess())) {
      _debug('Skipping Firebase sync - not logged in or no internet');
      return;
    }

    _debug('Starting Firebase sync...');
    try {
      await backupLocalDataToFirebase();
      await loadDataFromFirebase();
      _debug('Firebase sync completed successfully');
    } catch (e) {
      _debug('Firebase sync error: $e');
    }
  }

  Future<void> loadDataFromFirebase() async {
    if (!_authService.isLoggedIn) {
      _debug('Cannot load from Firebase - user not logged in');
      return;
    }

    _debug('Loading data from Firebase...');
    try {
      final userId = _authService.currentUser!.uid;
      
      // Load classes
      final classesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('classes')
          .get();

      _debug('Found ${classesSnapshot.docs.length} classes in Firebase');

      for (final doc in classesSnapshot.docs) {
        final classData = doc.data();
        final tutionClass = TutionClass.fromMap(classData);
        
        // Check if class already exists locally
        final existingClasses = getAllClasses();
        final exists = existingClasses.any((c) => c.id == tutionClass.id);
        
        if (!exists) {
          await _classesBox.add(tutionClass);
          _debug('Added class from Firebase: ${tutionClass.subject}');
        }
      }

      // Load payments
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('payments')
          .get();

      _debug('Found ${paymentsSnapshot.docs.length} payments in Firebase');

      for (final doc in paymentsSnapshot.docs) {
        final paymentData = doc.data();
        final payment = Payment.fromMap(paymentData);
        
        // Check if payment already exists locally
        final existingPayments = getAllPayments();
        final exists = existingPayments.any((p) => p.id == payment.id);
        
        if (!exists) {
          await _paymentsBox.add(payment);
          _debug('Added payment from Firebase: ${payment.subject} - ${payment.month}');
        }
      }

      _debug('Data loaded from Firebase successfully');
    } catch (e) {
      _debug('Error loading from Firebase: $e');
    }
  }

  Future<void> backupLocalDataToFirebase() async {
    if (!_authService.isLoggedIn) {
      _debug('Cannot backup to Firebase - user not logged in');
      return;
    }

    _debug('Backing up local data to Firebase...');
    try {
      final userId = _authService.currentUser!.uid;
      
      // Backup classes
      final classes = getAllClasses();
      _debug('Backing up ${classes.length} classes to Firebase');
      
      for (final tutionClass in classes) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('classes')
            .doc(tutionClass.id)
            .set(tutionClass.toMap(), SetOptions(merge: true));
      }

      // Backup payments
      final payments = getAllPayments();
      _debug('Backing up ${payments.length} payments to Firebase');
      
      for (final payment in payments) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('payments')
            .doc(payment.id)
            .set(payment.toMap(), SetOptions(merge: true));
      }

      _debug('Local data backed up to Firebase successfully');
    } catch (e) {
      _debug('Error backing up to Firebase: $e');
    }
  }

  // UTILITY METHODS
  String _getMonthName(int monthNumber) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[monthNumber - 1];
  }

  int _getMonthNumber(String monthName) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months.indexOf(monthName) + 1;
  }
}