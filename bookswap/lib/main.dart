import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'firebase_options.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/books_provider.dart';
import 'providers/swap_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // During local development use the Firebase Storage emulator to avoid CORS/billing
  if (kDebugMode) {
    try {
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
    } catch (_) {
      // ignore: avoid_print
      print('Could not connect to Storage emulator');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(create: (_) => SwapProvider()),
      ],
      child: const BookSwapApp(),
    );
  }
}
