import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/books_provider.dart';
import 'providers/swap_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/browse/browse_listings_screen.dart';
import 'screens/my_listings/my_listings_screen.dart';
import 'screens/chats/chat_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/custom_bottom_nav.dart';

/// Main app widget that configures theme and routing
class BookSwapApp extends StatelessWidget {
  const BookSwapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookSwap',
      debugShowCheckedModeBanner: false,

      // App theme matching the design (dark blue palette)
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E2746), // Dark blue from design
        scaffoldBackgroundColor: const Color(0xFF1E2746),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFFB84D), // Yellow/gold for buttons
          secondary: const Color(0xFF3D5A80), // Medium blue
          surface: const Color(0xFF2A3F5F), // Card background
        ),

        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E2746),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // Bottom navigation bar theme
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E2746),
          selectedItemColor: Color(0xFFFFB84D),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),

        // Text theme using Google Fonts (Noto Sans) with color/size overrides
        textTheme: GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme)
            .copyWith(
              headlineLarge: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headlineMedium: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              bodyLarge: const TextStyle(fontSize: 16, color: Colors.white70),
              bodyMedium: const TextStyle(fontSize: 14, color: Colors.white60),
            ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white38),
          labelStyle: const TextStyle(color: Colors.white70),
        ),

        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB84D),
            foregroundColor: const Color(0xFF1E2746),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      // Use Consumer to listen to AuthProvider and rebuild when auth state changes
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Show login screen if not authenticated
          // Show main app if authenticated
          return authProvider.isAuthenticated
              ? const MainScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}

/// MainScreen with bottom navigation
/// This is the container for all main app screens
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens corresponding to bottom nav items
  final List<Widget> _screens = [
    const BrowseListingsScreen(),
    const MyListingsScreen(),
    const ChatScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize providers when main screen loads
    _initializeProviders();
  }

  /// Initialize providers to start listening to Firebase streams
  void _initializeProviders() {
    final authProvider = context.read<AuthProvider>();
    final booksProvider = context.read<BooksProvider>();
    final swapProvider = context.read<SwapProvider>();

    // Get current user ID
    String? userId = authProvider.currentUser?.uid;

    if (userId != null) {
      // Start listening to real-time updates
      booksProvider.listenToAllBooks();
      booksProvider.listenToUserBooks(userId);
      swapProvider.listenToUserOffers(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the current screen based on selected index
      body: _screens[_currentIndex],

      // Custom bottom navigation bar
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          // If user taps the Chats item, open the chat list as a separate page
          if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
            return;
          }

          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
