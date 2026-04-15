import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const Color teal = Color(0xFF315A68);
  static const Color darkTeal = Color(0xFF1D3038);
  static const Color sandPeach = Color(0xFFE8BD8A);
  static const Color bgTeal = Color(0xFFE9EEF2); // Soft background color

  @override
  Widget build(BuildContext context) {
    // Obtenemos un poco del height para hacer la burbuja proporcional
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgTeal, // Fondo pastel completo parecido al lila
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Sección de la imagen (El círculo blanco detrás)
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // // Círculo blanco de fondo
                  // Container(
                  //   width: screenHeight * 0.40,
                  //   height: screenHeight * 0.40,
                  //   decoration: const BoxDecoration(
                  //     color: Colors.white,
                  //     shape: BoxShape.circle,
                  //   ),
                  // ),
                  // La Imagen (El árbol)
                  Image.asset(
                    'assets/images/tree_logo.png',
                    height: screenHeight * 0.35,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // Textos y Botones
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Sanar se',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: darkTeal,
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),
                    Text(
                      'siente bien.',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: darkTeal,
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botón Gradient (Get Started -> Registro)
                    Container(
                      height: 58,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF315A68), Color(0xFFE8BD8A)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: sandPeach.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Comenzar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Already have an account? Sign In -> Login real
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(
                            color: darkTeal.withOpacity(0.6),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Inicia sesión',
                            style: TextStyle(
                              color: teal,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
