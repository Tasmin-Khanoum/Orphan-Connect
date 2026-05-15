import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    try {
      User? user = _auth.currentUser;
      print('🔍 Getting user data for: ${user?.uid}');

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          print('✅ User document found');
          final userData = UserModel.fromMap(doc.data() as Map<String, dynamic>);
          print('✅ User role: ${userData.role}');
          return userData;
        } else {
          print('❌ User document does NOT exist in Firestore');
        }
      } else {
        print('❌ No current user in Firebase Auth');
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // Sign up
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String location,
    required String role,
  }) async {
    try {
      print('🔐 Starting registration for email: $email');

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Auth user created with UID: ${userCredential.user!.uid}');

      UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        location: location,
        role: role,
        createdAt: DateTime.now(),
        photoUrl: null,
      );

      print('💾 Saving user to Firestore...');
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toMap());
      print('✅ User saved successfully!');

      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');

      if (e.code == 'weak-password') {
        return 'The password is too weak. Please use at least 6 characters.';
      } else if (e.code == 'email-already-in-use') {
        return 'An account already exists with this email.';
      } else if (e.code == 'invalid-email') {
        return 'The email address is not valid.';
      } else {
        return 'Registration failed: ${e.message}';
      }
    } on FirebaseException catch (e) {
      print('❌ FirebaseException: ${e.code} - ${e.message}');
      return 'Database error: ${e.message}';
    } catch (e) {
      print('❌ Unknown error: $e');
      return 'Registration failed: $e';
    }
  }

  // Sign in
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth successful for: ${userCredential.user?.uid}');
      print('✅ User email verified: ${userCredential.user?.emailVerified}');

      // Check if user document exists
      final doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (doc.exists) {
        print('✅ User document exists in Firestore');
        final userData = doc.data();
        print('✅ User role: ${userData?['role']}');
      } else {
        print('⚠️ WARNING: User authenticated but NO Firestore document found!');
      }

      notifyListeners();
      print('✅ Login completed successfully');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException during login: ${e.code} - ${e.message}');

      if (e.code == 'user-not-found') {
        return 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      } else if (e.code == 'user-disabled') {
        return 'This account has been disabled.';
      } else if (e.code == 'invalid-credential') {
        return 'Invalid email or password.';
      } else {
        return 'Login failed: ${e.message}';
      }
    } catch (e) {
      print('❌ Unknown login error: $e');
      return 'Login failed: $e';
    }
  }

  // Forgot Password
  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No account found with this email.';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      } else {
        return 'Failed to send reset email: ${e.message}';
      }
    } catch (e) {
      return 'Failed to send reset email: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    print('🚪 Signing out...');
    await _auth.signOut();
    notifyListeners();
    print('✅ Signed out successfully');
  }

  // Update user profile
  Future<String?> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String location,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
        'location': location,
      });
      notifyListeners();
      return null; // Success
    } catch (e) {
      print('Error updating profile: $e');
      return 'Failed to update profile: $e';
    }
  }

  // Update user photo
  Future<String?> updateUserPhoto(String uid, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': photoUrl,
      });
      notifyListeners();
      return null; // Success
    } catch (e) {
      print('Error updating photo: $e');
      return 'Failed to update photo: $e';
    }
  }
}