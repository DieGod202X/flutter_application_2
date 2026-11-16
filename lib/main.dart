import 'package:flutter/material.dart';
import 'package:login_osito_rive/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  // 1. Asegurar la vinculación de widgets
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar Firebase obligatoriamente antes de runApp
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rive Animated Login',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginScreen(), // Tu pantalla inicial con el osito
    );
  }
}
