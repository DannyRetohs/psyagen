import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/agenda_provider.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await initializeDateFormatting('es_ES', null);
  await NotificationService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AgendaProvider()),
      ],
      child: const PsicoAgendaApp(),
    ),
  );
}

class PsicoAgendaApp extends StatelessWidget {
  const PsicoAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos nuestra paleta de colores Pastel Purple Glass
    const pastelPurple = Color(0xFFCE93D8); // Purple 200
    const pastelPink = Color(0xFFF48FB1); // Pink 200
    const deepPurple = Color(0xFF4A148C); // Para textos
    
    // Forzamos un texto oscuro legibe (deep purple) en fondos pastel
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    return MaterialApp(
      title: 'SereneMind Agenda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light, 
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: pastelPurple,
          primary: pastelPurple,
          secondary: pastelPink,
          surface: Colors.white.withOpacity(0.5), // Base de contenedor glass
          onPrimary: Colors.white, // Texto dentro de botones primarios
        ),
        // Scaffolds deben ser transparentes para que LiquidBackground se vea debajo
        scaffoldBackgroundColor: Colors.transparent, 
        textTheme: textTheme.apply(
          bodyColor: deepPurple,
          displayColor: deepPurple,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: deepPurple,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: deepPurple,
            letterSpacing: 1.2,
          ),
          iconTheme: const IconThemeData(color: deepPurple),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.transparent, // Dejaremos que GlassContainer maneje esto visualmente
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: pastelPurple.withOpacity(0.9), // Semi-transparente
            foregroundColor: Colors.white, // Texto blanco clásico en botones
            elevation: 8,
            shadowColor: pastelPurple.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: pastelPink.withOpacity(0.9),
          foregroundColor: Colors.white,
          elevation: 8,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(30))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.4), // Inputs claros y translúcidos
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: pastelPurple.withOpacity(0.3), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: pastelPurple.withOpacity(0.5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: pastelPurple, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          labelStyle: TextStyle(color: deepPurple.withOpacity(0.7), fontWeight: FontWeight.w500),
          hintStyle: TextStyle(color: deepPurple.withOpacity(0.4)),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
