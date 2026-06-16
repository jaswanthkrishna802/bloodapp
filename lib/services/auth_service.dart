import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Register with email & password
  Future<UserModel?> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String bloodGroup,
    required String location,
    required String city,
    required String state,
    required String role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
      await cred.user!.updateDisplayName(name);

      final user = UserModel(
        id: cred.user!.uid,
        name: name,
        phone: phone,
        email: email,
        bloodGroup: bloodGroup,
        location: location,
        city: city,
        state: state,
        role: role,
        isAvailable: true,
      );
      await _db.collection('users').doc(cred.user!.uid).set(user.toJson());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Login with email & password
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      return await getUserById(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Phone OTP - send
  Future<void> sendOtp({
    required String phone,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential cred) async {
        await _auth.signInWithCredential(cred);
      },
      verificationFailed: (FirebaseAuthException e) => onError(e.message ?? 'OTP failed'),
      codeSent: (String vId, int? resendToken) => onCodeSent(vId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // Phone OTP - verify
  Future<UserModel?> verifyOtp(String verificationId, String smsCode) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
      final result = await _auth.signInWithCredential(cred);
      final uid = result.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) return UserModel.fromJson({...doc.data()!, 'id': uid});
      return null;
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  // Fetch user by ID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson({...doc.data()!, 'id': doc.id});
  }

  // Update availability
  Future<void> updateAvailability(String uid, bool available) async {
    await _db.collection('users').doc(uid).update({'isAvailable': available});
  }

  // Sign out
  Future<void> signOut() async => await _auth.signOut();

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already registered.';
      case 'invalid-email': return 'Invalid email address.';
      case 'weak-password': return 'Password too weak (min 6 chars).';
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'too-many-requests': return 'Too many attempts. Try later.';
      default: return 'Authentication failed. Try again.';
    }
  }
}
