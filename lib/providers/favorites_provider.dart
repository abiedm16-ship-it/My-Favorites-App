import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  String _userId = '';
  List<Product> _favorites = [];
  bool _isLoading = false;
  StreamSubscription<List<Product>>? _favoritesSubscription;

  List<Product> get favorites => _favorites;
  bool get isLoading => _isLoading;

  // Called when Auth state changes to set the active user ID and load favorites
  void updateUserId(String userId) {
    if (_userId == userId) return;
    
    _userId = userId;
    _favoritesSubscription?.cancel();
    _favoritesSubscription = null;
    
    if (userId.isEmpty) {
      _favorites = [];
      notifyListeners();
      return;
    }

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    if (FirebaseService.isFirebaseInitialized) {
      // Firebase Mode: Listen to Firestore changes in real-time
      _favoritesSubscription = _firebaseService.getUserFavorites(_userId).listen(
        (favList) {
          _favorites = favList;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error in favorites stream subscription: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      // Demo Mode: Load favorites from SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final String? favsJson = prefs.getString('demo_favorites_$_userId');
        if (favsJson != null) {
          final List<dynamic> decoded = json.decode(favsJson);
          _favorites = decoded.map((item) => Product.fromJson(item)).toList();
        } else {
          _favorites = [];
        }
      } catch (e) {
        debugPrint('Error loading demo favorites: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Check if a product is favorited
  bool isFavorite(int productId) {
    return _favorites.any((product) => product.id == productId);
  }

  // Toggle Favorite
  Future<void> toggleFavorite(Product product) async {
    if (_userId.isEmpty) return;

    final bool currentlyFavorite = isFavorite(product.id);

    if (currentlyFavorite) {
      // Remove from favorites
      if (FirebaseService.isFirebaseInitialized) {
        await _firebaseService.removeFavorite(_userId, product.id);
      } else {
        // Demo Mode: Update locally
        _favorites.removeWhere((p) => p.id == product.id);
        await _saveDemoFavoritesToPrefs();
        notifyListeners();
      }
    } else {
      // Add to favorites
      if (FirebaseService.isFirebaseInitialized) {
        await _firebaseService.addFavorite(_userId, product);
      } else {
        // Demo Mode: Update locally
        _favorites.add(product);
        await _saveDemoFavoritesToPrefs();
        notifyListeners();
      }
    }
  }

  // Demo Helper to serialize favorites list to Shared Preferences
  Future<void> _saveDemoFavoritesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        _favorites.map((product) => product.toJson()).toList(),
      );
      await prefs.setString('demo_favorites_$_userId', encoded);
    } catch (e) {
      debugPrint('Error saving demo favorites: $e');
    }
  }

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    super.dispose();
  }
}
