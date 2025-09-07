import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('guest_mode') ?? true;
  }

  // Set guest mode
  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', isGuest);
  }

  // Track registration prompts
  Future<bool> shouldShowRegistrationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPrompt = prefs.getInt('last_registration_prompt') ?? 0;
    final promptCount = prefs.getInt('registration_prompt_count') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Show prompt after 24 hours and every 3 days after that, max 5 times
    if (promptCount >= 5) return false;
    if (promptCount == 0) return true; // First time opening
    
    const dayInMs = 24 * 60 * 60 * 1000;
    final timeSinceLastPrompt = now - lastPrompt;
    
    return timeSinceLastPrompt > (3 * dayInMs);
  }

  // Record registration prompt shown
  Future<void> recordRegistrationPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    final promptCount = prefs.getInt('registration_prompt_count') ?? 0;
    await prefs.setInt('last_registration_prompt', DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt('registration_prompt_count', promptCount + 1);
  }

  // Register user
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String studentType,
    required String year,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email,
        'studentType': studentType,
        'year': year,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await setGuestMode(false);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred during registration';
    }
  }

  // Login user
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await setGuestMode(false);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An error occurred during login';
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
    await setGuestMode(true);
  }

  // Get available years from Firebase (admin managed)
  Future<List<String>> getAvailableYears(String studentType) async {
    try {
      final doc = await _firestore.collection('app_config').doc('student_years').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final years = List<String>.from(data[studentType.toLowerCase()] ?? []);
        return years;
      }
      
      // Default years if not found in Firebase
      if (studentType.toLowerCase() == 'a/l student') {
        return ['2024', '2025', '2026'];
      } else {
        return ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11'];
      }
    } catch (e) {
      // Return default years on error
      if (studentType.toLowerCase() == 'a/l student') {
        return ['2024', '2025', '2026'];
      } else {
        return ['Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11'];
      }
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Get user name
  Future<String?> getUserName() async {
    final profile = await getUserProfile();
    return profile?['name'];
  }
}