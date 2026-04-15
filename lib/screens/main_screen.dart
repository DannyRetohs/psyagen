import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'home_screen.dart';
import 'patient_list_screen.dart';
import 'monthly_report_screen.dart';
import '../widgets/liquid_background.dart';
import '../widgets/glass_container.dart';
import '../services/auth_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    PatientListScreen(),
    MonthlyReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF315A68)),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Estás seguro que quieres salir?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Salir', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await AuthService().signOut();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              child: GNav(
                rippleColor: Colors.black12,
                hoverColor: Colors.black12,
                gap: 8,
                activeColor: Theme.of(context).colorScheme.primary,
                iconSize: 26,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: Colors.white.withOpacity(0.5),
                color: Colors.black54,
                textStyle: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                tabs: const [
                  GButton(
                    icon: Icons.dashboard_rounded,
                    text: 'Agenda',
                  ),
                  GButton(
                    icon: Icons.people_alt_rounded,
                    text: 'Pacientes',
                  ),
                  GButton(
                    icon: Icons.analytics_rounded,
                    text: 'Reportes',
                  ),
                ],
                selectedIndex: _currentIndex,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
