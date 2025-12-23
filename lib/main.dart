import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uni_escom/services/auth/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UniEscomApp());
}

class UniEscomApp extends StatelessWidget {
  const UniEscomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniEscom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(), 
    );
  }
}