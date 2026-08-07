import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import 'home_screen.dart';
import 'trips_screen.dart';
import 'profile_screen.dart';

/// Shell principal com bottom navigation (spec §23).
///
/// Três abas: Início, Viagem, Perfil.
/// O SOS é um comando global (não é aba) — aparece dentro das telas.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    TripsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Carrega histórico ao entrar no app.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: const Color(0xFFFF0000),
        unselectedItemColor: Colors.white38,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined), label: 'Viagem'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}
