import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/friend_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

/// MotoHead — Sua estrada. Nossa história.
///
/// App mobile "companheiro de estrada" do motociclista (spec §1, §2).
/// MVP: Início, Viagem (tracking GPS), SOS, Perfil.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MotoHeadApp());
}

class MotoHeadApp extends StatelessWidget {
  const MotoHeadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
      ],
      child: MaterialApp(
        title: 'MotoHead',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF0000),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),
        ),
        home: const _BootGate(),
      ),
    );
  }
}

/// Porta de entrada: decide entre Login e MainShell.
/// MVP: sem persistência — sempre mostra Login.
class _BootGate extends StatelessWidget {
  const _BootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const _Splash();
    }

    // MVP: sem persistência — sempre mostra Login
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    return const MainShell();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.motorcycle, size: 96, color: Color(0xFFFF0000)),
            SizedBox(height: 16),
            Text(
              'MOTOHEAD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sua estrada. Nossa história.',
              style: TextStyle(
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Color(0xFFFF0000), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
