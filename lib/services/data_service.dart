import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/tution_class.dart';
import '../models/payment.dart';
import 'auth_service.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final Uuid _uuid = const Uuid();

  // 👉 FIX: Box type එක TutionClass විදියට වෙනස් කලා
  late Box<TutionClass> _classesBox;

  // --- මේ ටික දැනට වෙනස් කරන්නෙ නෑ ---
  static const String paymentsBoxName = 'payments';
  static const String syncQueueBoxName = 'sync_queue';
  late Box<Map> _paymentsBox;
  late Box<Map> _syncQueueBox;
  // ------------------------------------

  Future<void> initializeHive() async {
    // Box එක main.dart වල open කරපු නිසා, මෙතනදි ඒක අරගන්නවා විතරයි
    _classesBox = Hive.box<TutionClass>('classes');
    _paymentsBox = await Hive.openBox<Map>(paymentsBoxName);
    _syncQueueBox = await Hive.openBox<Map>(syncQueueBoxName);
  }

  Future<bool> hasInternetAccess() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> addClass(TutionClass tutionClass) async {
    // 👉 FIX: Code එක simple උනා. Object එක කෙලින්ම save කරනවා
    await _classesBox.add(tutionClass);

    // TODO: Firebase sync logic එක පස්සෙ හදමු.
    // දැනට local save වෙන එක හරියටම වැඩ.
  }

  List<TutionClass> getAllClasses() {
    // 👉 FIX: Code එක simple උනා. Box එකේ values ටික list එකක් කරනවා.
    return _classesBox.values.toList();
  }

  // =======================================================
  // පහල තියෙන අනිත් functions දැනට වෙනස් කරන්නෙ නෑ.
  // අපි Firebase sync එක හදද්දි මේ ටිකත් update කරමු.
  // =======================================================

  Future<void> syncWithFirebase() async { /* ... no change ... */ }
  Future<void> addPayment(Payment payment) async { /* ... no change ... */ }
  List<Payment> getAllPayments() { /* ... no change ... */ return []; }
  Future<void> _syncClasses() async { /* ... no change ... */ }
  Future<void> _syncSingleClass(String id, Map classData) async { /* ... no change ... */ }
  Future<void> _syncPayments() async { /* ... no change ... */ }
  Future<void> _syncSinglePayment(String id, Map paymentData) async { /* ... no change ... */ }
  Future<void> loadDataFromFirebase() async { /* ... no change ... */ }
  Future<void> backupLocalDataToFirebase() async { /* ... no change ... */ }
}