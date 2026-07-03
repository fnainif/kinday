import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kinday/models/user_model_firebase.dart';

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current active Firebase user
  User? get currentUser => _auth.currentUser;

  // Register User
  Future<bool> registerUser(UserModelFirebase pengguna) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: pengguna.email,
        password: pengguna.password,
      );

      if (credential.user != null) {
        final userWithUid = pengguna.copyWith(uid: credential.user!.uid);
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userWithUid.toFirestore());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error registering user: $e");
      rethrow;
    }
  }

  // Login User
  Future<UserModelFirebase?> loginUser(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final profile = await getUserById(credential.user!.uid);
        if (profile == null) {
          debugPrint("Firestore profile document not found for UID: ${credential.user!.uid}. Recreating stub profile.");
          final stubProfile = UserModelFirebase(
            uid: credential.user!.uid,
            username: email.split('@').first,
            email: email,
            password: password,
          );
          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(stubProfile.toFirestore());
          return stubProfile;
        }
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint("Error logging in user: $e");
      rethrow;
    }
  }

  // Get User by Email
  Future<UserModelFirebase?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModelFirebase.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting user by email: $e");
      rethrow;
    }
  }

  // Get User by ID (UID)
  Future<UserModelFirebase?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModelFirebase.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint("Error getting user by ID: $e");
      rethrow;
    }
  }

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email, {String? excludeUid}) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        if (excludeUid != null) {
          return querySnapshot.docs.any((doc) => doc.id != excludeUid);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking if email registered: $e");
      return false;
    }
  }

  // Get all users
  Future<List<UserModelFirebase>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserModelFirebase.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint("Error getting all users: $e");
      return [];
    }
  }

  // Delete User
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      final user = _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
      }
    } catch (e) {
      debugPrint("Error deleting user: $e");
    }
  }

  // Update User
  Future<bool> updateUser(UserModelFirebase pengguna) async {
    if (pengguna.uid == null) return false;
    try {
      await _firestore
          .collection('users')
          .doc(pengguna.uid)
          .update(pengguna.toFirestore());
      return true;
    } catch (e) {
      debugPrint("Error updating user: $e");
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send Password Reset Email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint("Error sending password reset email: $e");
      return false;
    }
  }
}
