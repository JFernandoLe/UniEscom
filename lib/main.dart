import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uni_escom/services/auth/login_screen.dart';
import 'firebase_options.dart';
import 'services/notifications/bloc/notifications_bloc.dart';
import 'services/notifications/bloc/notification_local_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await LocalNotificationService.instance.init();
  runApp(
    MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => NotificationsBloc()..add(const NotificationsInitRequested()),
      ), 
    ],
    child: const UniEscomApp())
  );
}

class UniEscomApp extends StatelessWidget {
  const UniEscomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniEscom',
      debugShowCheckedModeBanner: false,

      // THEME GLOBAL (el diseño)
      theme: ThemeData(
        useMaterial3: true,

        // Color base de la app
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),

        scaffoldBackgroundColor: Colors.white,

        // Inputs (TextField / TextFormField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.withOpacity(0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.30),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1565C0),
              width: 1.6,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),

        // Botones principales
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // AppBar consistente
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      // Pantalla inicial
      home: const LoginScreen(),
    );
  }
}
