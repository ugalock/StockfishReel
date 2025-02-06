import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if username is valid format
  bool isUsernameValidFormat(String username) {
    if (!username.startsWith('@')) {
      return false;
    }
    
    // Username should be at least 4 characters (@ + 3 chars)
    if (username.length < 4) {
      return false;
    }

    // Add any other format validation rules here
    return true;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    // First validate username format
    if (!isUsernameValidFormat(username)) {
      throw AuthException(
        'Invalid username format. Username must start with @ and be at least 6 characters long.',
      );
    }

    UserCredential? userCredential;
    try {
      // Step 1: Create the Firebase Auth user
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Call the cloud function to create user documents
      try {
        await _functions.httpsCallable('createUser').call({
          'userId': userCredential.user!.uid,
          'username': username,
          'email': email,
        });

        // If we get here, both the Auth user and Firestore documents were created successfully
        return userCredential;
      } catch (e) {
        // Step 3a: If cloud function fails, delete the auth user and throw
        if (userCredential.user != null) {
          await userCredential.user!.delete();
        }
        throw AuthException(_handleCloudFunctionError(e));
      }
    } on FirebaseAuthException catch (e) {
      // Step 3b: If auth creation fails, clean up if needed and throw
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }
      throw _handleAuthException(e);
    } catch (e) {
      // Step 3c: Handle any other errors, clean up if needed
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }
      throw AuthException('An unexpected error occurred during signup.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No user found with this email.');
      case 'wrong-password':
        return AuthException('Wrong password provided.');
      case 'email-already-in-use':
        return AuthException('Email is already in use.');
      case 'invalid-email':
        return AuthException('Invalid email address.');
      case 'weak-password':
        return AuthException('Password is too weak.');
      case 'operation-not-allowed':
        return AuthException('Operation not allowed.');
      case 'user-disabled':
        return AuthException('User has been disabled.');
      default:
        return AuthException(e.message ?? 'An unknown error occurred.');
    }
  }

  // Handle Cloud Function errors
  String _handleCloudFunctionError(dynamic error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'already-exists':
          return 'Username is already taken.';
        case 'invalid-argument':
          return 'Invalid username format.';
        default:
          return error.message ?? 'An error occurred while creating your account.';
      }
    }
    return 'An unexpected error occurred while creating your account.';
  }
}

// Custom Auth Exception
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
} 