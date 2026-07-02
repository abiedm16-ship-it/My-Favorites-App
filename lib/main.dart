import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/favorites_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase, fallback to Demo Mode if options are default or fail
  try {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    if (apiKey.isNotEmpty && !apiKey.contains('YOUR_')) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("Firebase initialized successfully.");
    } else {
      debugPrint("Firebase options contain placeholder keys. Running in Demo Mode.");
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e. Running in Demo Mode.");
  }

  runApp(const MyFavoritesApp());
}

class MyFavoritesApp extends StatelessWidget {
  const MyFavoritesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'تطبيق مفضلاتي - My Favorites App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1E3C40),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3C40),
            brightness: Brightness.dark,
            primary: const Color(0xFF1E3C40),
            secondary: Colors.tealAccent,
          ),
          textTheme: GoogleFonts.cairoTextTheme(
            ThemeData.dark().textTheme,
          ),
        ),
        // Force right-to-left layout since the app is mainly in Arabic
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', 'AE'), // Arabic
          Locale('en', 'US'), // English fallback
        ],
        locale: const Locale('ar', 'AE'),
        
        home: const AppRoot(),
      ),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.tealAccent,
          ),
        ),
      );
    }

    // Switch between LoginScreen and HomeScreen depending on login status
    return authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
