import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class FirebaseService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Check if Firebase is initialized
  static bool get isFirebaseInitialized => Firebase.apps.isNotEmpty;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Authentication
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<UserCredential?> signUp(String email, String password) async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase is not initialized. Mocking SignUp.');
      return null;
    }
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign In
  Future<UserCredential?> signIn(String email, String password) async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase is not initialized. Mocking SignIn.');
      return null;
    }
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase is not initialized. Mocking SignOut.');
      return;
    }
    await _auth.signOut();
  }

  // Add Product to Favorites
  Future<void> addFavorite(String userId, Product product) async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase is not initialized. Saving favorite locally/mock.');
      return;
    }
    try {
      // Document ID is userId_productId to ensure uniqueness
      final String docId = '${userId}_${product.id}';
      await _firestore.collection('favorites').doc(docId).set({
        'userId': userId,
        'productId': product.id,
        'title': product.title,
        'price': product.price,
        'image': product.image,
        'category': product.category,
        'description': product.description,
        'ratingRate': product.ratingRate,
        'ratingCount': product.ratingCount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore Error adding favorite: $e');
      rethrow;
    }
  }

  // Remove Product from Favorites
  Future<void> removeFavorite(String userId, int productId) async {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase is not initialized. Removing favorite locally/mock.');
      return;
    }
    try {
      final String docId = '${userId}_$productId';
      await _firestore.collection('favorites').doc(docId).delete();
    } catch (e) {
      debugPrint('Firestore Error removing favorite: $e');
      rethrow;
    }
  }

  // Stream Favorites for a specific User
  Stream<List<Product>> getUserFavorites(String userId) {
    if (!isFirebaseInitialized) {
      debugPrint('Firebase is not initialized. Returning empty stream for favorites.');
      return const Stream.empty();
    }
    try {
      return _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return Product(
            id: data['productId'] as int,
            title: data['title'] ?? '',
            price: (data['price'] as num).toDouble(),
            description: data['description'] ?? '',
            category: data['category'] ?? '',
            image: data['image'] ?? '',
            ratingRate: (data['ratingRate'] as num).toDouble(),
            ratingCount: data['ratingCount'] as int,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Firestore Error fetching stream of favorites: $e');
      return const Stream.empty();
    }
  }

  // One-time Fetch of Favorites for a user (useful for initial state load)
  Future<List<Product>> fetchUserFavoritesOnce(String userId) async {
    if (!isFirebaseInitialized) {
      return [];
    }
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Product(
          id: data['productId'] as int,
          title: data['title'] ?? '',
          price: (data['price'] as num).toDouble(),
          description: data['description'] ?? '',
          category: data['category'] ?? '',
          image: data['image'] ?? '',
          ratingRate: (data['ratingRate'] as num).toDouble(),
          ratingCount: data['ratingCount'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('Firestore Error fetching favorites once: $e');
      return [];
    }
  }
}
