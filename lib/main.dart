import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'providers/agenda_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
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
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
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
    const darkTeal = Color(0xFF1D3038);    // Textos muy oscuros
    const teal = Color(0xFF315A68);         // Primario dominante
    const sandPeach = Color(0xFFE8BD8A);    // Acento / secundario
    const warmCoral = Color(0xFFD08C78);    // Terciario de alerta
    
    // Forzamos un texto oscuro legibe (deep purple) en fondos pastel
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

    return MaterialApp(
      title: 'PsicPac',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light, 
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: teal,
          primary: teal,            // Teal como primario dominante
          secondary: sandPeach,     // Durazno como acento
          surface: Colors.white.withOpacity(0.5), // Base de contenedor glass
          onPrimary: Colors.white, // Texto dentro de botones primarios
          onSecondary: Colors.white,
        ),
        // Scaffolds deben ser transparentes para que LiquidBackground se vea debajo
        scaffoldBackgroundColor: Colors.transparent, 
        textTheme: textTheme.apply(
          bodyColor: darkTeal,
          displayColor: darkTeal,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: darkTeal,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: darkTeal,
            letterSpacing: 1.2,
          ),
          iconTheme: const IconThemeData(color: darkTeal),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.transparent, // Dejaremos que GlassContainer maneje esto visualmente
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: teal,         // Botones fuertemente teal
            foregroundColor: Colors.white, // Texto blanco clásico en botones
            elevation: 8,
            shadowColor: teal.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: teal,            // FAB teal dominante
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
            borderSide: BorderSide(color: teal.withOpacity(0.3), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: teal.withOpacity(0.5), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: teal, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
          labelStyle: TextStyle(color: darkTeal.withOpacity(0.7), fontWeight: FontWeight.w500),
          hintStyle: TextStyle(color: darkTeal.withOpacity(0.4)),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFE8F2F5),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF315A68)),
              ),
            );
          }
          if (snapshot.hasData) {
            return const MainScreen(); // Sesión activa → app
          }
          return const LoginScreen(); // Sin sesión → login
        },
      ),
    );
  }
}
