import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

        // Send email verification automatically after registration
        await credential.user!.sendEmailVerification();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error registering user: $e");
      rethrow;
    }
  }

  // Send Email Verification to the currently signed-in user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if the currently signed-in user's email is verified
  // Reloads the user profile first to get the latest status from Firebase
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
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

  // Sign In with Google
  Future<UserModelFirebase?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final email = user.email ?? '';
        final username = user.displayName ?? (email.isNotEmpty ? email.split('@').first : 'Google User');
        
        final profile = await getUserById(user.uid);
        if (profile == null) {
          debugPrint("Firestore profile document not found for UID: ${user.uid}. Creating new profile.");
          final newProfile = UserModelFirebase(
            uid: user.uid,
            username: username,
            email: email,
            password: '', // Google authentication does not use passwords
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(newProfile.toFirestore());
          return newProfile;
        }
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
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

  // Change Password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      // 1. Reauthenticate the user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update password in Firebase Auth
      await user.updatePassword(newPassword);

      // 3. Update password in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'password': newPassword});

      return true;
    } catch (e) {
      debugPrint("Error changing password in Firebase: $e");
      rethrow;
    }
  }

  // Link Google credential to current Firebase user
  Future<UserCredential?> linkGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // Cancelled by user
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await user.linkWithCredential(credential);
      
      // Sync email in Firestore
      final email = userCredential.user?.email;
      if (email != null && email.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'email': email});
      }
      return userCredential;
    } catch (e) {
      debugPrint("Error linking Google: $e");
      rethrow;
    }
  }

  // Link Email/Password credential to current Firebase user
  Future<UserCredential?> linkEmail(String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }

      final AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final userCredential = await user.linkWithCredential(credential);
      
      // Sync email & password in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
            'email': email,
            'password': password,
          });

      return userCredential;
    } catch (e) {
      debugPrint("Error linking Email: $e");
      rethrow;
    }
  }

  // Unlink provider from current Firebase user
  Future<User?> unlinkProvider(String providerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }

      final updatedUser = await user.unlink(providerId);
      return updatedUser;
    } catch (e) {
      debugPrint("Error unlinking provider: $e");
      rethrow;
    }
  }
}
