import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String _userId = '';
  String _userEmail = '';
  String _username = '';

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId;
  String get userEmail => _userEmail;
  String get username => _username;

  AuthProvider() {
    _init();
  }

  // Initialize and check current auth state
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? '';

    if (FirebaseService.isFirebaseInitialized) {
      // Firebase is connected, check current user
      _firebaseService.authStateChanges.listen((User? user) {
        if (user != null) {
          _isLoggedIn = true;
          _userId = user.uid;
          _userEmail = user.email ?? '';
        } else {
          _isLoggedIn = false;
          _userId = '';
          _userEmail = '';
        }
        _isLoading = false;
        notifyListeners();
      });
    } else {
      // Demo Mode: Check local storage for login status
      final demoLoggedIn = prefs.getBool('demo_is_logged_in') ?? false;
      if (demoLoggedIn) {
        _isLoggedIn = true;
        _userId = prefs.getString('demo_user_id') ?? 'demo_user_123';
        _userEmail = prefs.getString('demo_user_email') ?? 'demo@example.com';
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register / Sign Up
  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (FirebaseService.isFirebaseInitialized) {
        final credential = await _firebaseService.signUp(email, password);
        if (credential != null && credential.user != null) {
          _userId = credential.user!.uid;
          _userEmail = credential.user!.email ?? '';
          _isLoggedIn = true;
          
          // Save username locally
          _username = username;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', username);
          
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        // Demo Mode Success
        _userId = 'demo_user_123';
        _userEmail = email;
        _username = username;
        _isLoggedIn = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setBool('demo_is_logged_in', true);
        await prefs.setString('demo_user_id', _userId);
        await prefs.setString('demo_user_email', email);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    return false;
  }

  // Sign In / Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (FirebaseService.isFirebaseInitialized) {
        final credential = await _firebaseService.signIn(email, password);
        if (credential != null && credential.user != null) {
          _userId = credential.user!.uid;
          _userEmail = credential.user!.email ?? '';
          _isLoggedIn = true;
          
          // Attempt to restore username if stored locally, or default to part of email
          final prefs = await SharedPreferences.getInstance();
          _username = prefs.getString('username') ?? email.split('@')[0];
          await prefs.setString('username', _username);

          _isLoading = false;
          notifyListeners();
          return true;
        }
      } else {
        // Demo Mode check
        if (email.isNotEmpty && password.isNotEmpty) {
          _userId = 'demo_user_123';
          _userEmail = email;
          _isLoggedIn = true;

          final prefs = await SharedPreferences.getInstance();
          _username = prefs.getString('username') ?? email.split('@')[0];
          await prefs.setString('username', _username);
          await prefs.setBool('demo_is_logged_in', true);
          await prefs.setString('demo_user_id', _userId);
          await prefs.setString('demo_user_email', email);

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
    return false;
  }

  // Sign Out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    if (FirebaseService.isFirebaseInitialized) {
      await _firebaseService.signOut();
    } else {
      // Clear demo login status but keep the stored username for autocomplete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('demo_is_logged_in', false);
      await prefs.remove('demo_user_id');
      await prefs.remove('demo_user_email');
    }

    _isLoggedIn = false;
    _userId = '';
    _userEmail = '';
    _isLoading = false;
    notifyListeners();
  }

  // Helper method to update the stored username directly
  Future<void> updateUsername(String newName) async {
    _username = newName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
    notifyListeners();
  }
}
