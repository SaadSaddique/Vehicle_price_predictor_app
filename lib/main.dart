import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/FirebaseHelper.dart';
import 'models/UserModel.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/FirebaseHelper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Initialize Firebase
  await Firebase.initializeApp();
  print("App Initialized Successfully!!");
  await dotenv.load(fileName: ".env");
  print(".Env Loaded Successfully!!");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vehicle Price Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.blue.shade700,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade700,
          secondary: Colors.blue.shade300,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
