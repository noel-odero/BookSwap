import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// AuthProvider manages authentication state using Provider pattern
/// ChangeNotifier allows widgets to rebuild when auth state changes
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters expose private state to UI
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  /// Constructor listens to Firebase auth state changes
  /// This makes the app reactive to login/logout events
  AuthProvider() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null && user.emailVerified) {
        // User is logged in and verified, fetch full user data
        _currentUser = await _authService.getCurrentUserModel();
      } else {
        // User is logged out or not verified
        _currentUser = null;
      }
      // Notify all listening widgets to rebuild
      notifyListeners();
    });
  }

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      UserModel? user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (user != null) {
        // Note: Don't set _currentUser yet because email isn't verified
        _setLoading(false);
        return true;
      }

      _error = 'Sign up failed';
      _setLoading(false);
      return false;
    } catch (e) {
      // Provide friendlier messages for common FirebaseAuth errors
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            _error = 'The email address is not valid.';
            break;
          case 'email-already-in-use':
            _error = 'This email is already in use. Try signing in.';
            break;
          case 'weak-password':
            _error = 'The password is too weak. Use at least 6 characters.';
            break;
          case 'operation-not-allowed':
            _error =
                'Email/password sign-in is disabled for this project. Enable it in the Firebase console.';
            break;
          default:
            _error = e.message ?? e.toString();
        }
      } else {
        _error = e.toString();
      }
      _setLoading(false);
      return false;
    }
  }

  /// Sign in existing user
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _error = null;

    try {
      UserModel? user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      }

      _error = 'Sign in failed';
      _setLoading(false);
      return false;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _error = 'No user found for that email.';
            break;
          case 'wrong-password':
            _error = 'Incorrect password provided.';
            break;
          case 'invalid-email':
            _error = 'The email address is not valid.';
            break;
          case 'user-disabled':
            _error = 'This user has been disabled.';
            break;
          case 'operation-not-allowed':
            _error = 'This sign-in method is not enabled for the project.';
            break;
          default:
            _error = e.message ?? e.toString();
        }
      } else {
        _error = e.toString();
      }
      _setLoading(false);
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Helper method to set loading state and notify listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
