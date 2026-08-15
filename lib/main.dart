import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/friend_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/app_logger.dart';
import 'services/tracking_service.dart';

/// MotoHead — Sua estrada. Nossa história.
///
/// App mobile "companheiro de estrada" do motociclista (spec §1, §2).
/// MVP: Início, Viagem (tracking GPS), SOS, Perfil.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();
  AppLogger.info('APP', 'MotoHead iniciando...');

  // Inicializa o serviço de tracking e solicita permissão de notificação
  // cedo no ciclo de vida — fazer isso durante startTrip() causa crash
  // porque o Android recria a Activity ao conceder a permissão.
  _initTracking();

  runApp(const MotoHeadApp());
}

Future<void> _initTracking() async {
  try {
    await TrackingService.initialize();
    // Solicita permissão de notificação em background (não bloqueia o app)
    // O dialog do sistema aparece, mas como é no início, não há tracking
    // em andamento para perder contexto.
    await TrackingService.requestNotificationPermission();
  } catch (e) {
    AppLogger.error('APP', 'Erro ao inicializar tracking: $e');
  }
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
/// Restaura a sessão persistida (manter logado) no boot.
class _BootGate extends StatefulWidget {
  const _BootGate();

  @override
  State<_BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<_BootGate> {
  bool _restoreStarted = false;

  @override
  void initState() {
    super.initState();
    // Restaura sessão persistida (manter logado).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_restoreStarted && mounted) {
        _restoreStarted = true;
        context.read<AuthProvider>().restore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const _Splash();
    }

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
