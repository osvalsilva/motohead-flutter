import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/sos_button.dart';
import 'trip_tracking_screen.dart';

/// Tela Inicial (spec §4) — painel resumido do motociclista.
///
/// Mostra:
/// - saudação + moto principal (placeholder)
/// - viagem em andamento (prioridade visual) ou atalho para iniciar
/// - eventos relevantes (placeholder)
/// - botão de SOS
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trips = context.watch<TripProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          AppConfig.appName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFFF0000),
              child: Text(
                (user?.firstName.isNotEmpty ?? false)
                    ? user!.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF0000),
        onRefresh: () => trips.loadHistory(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Saudação
            Text(
              'Olá, ${user?.firstName ?? "motociclista"}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              AppConfig.slogan,
              style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),

            // Moto principal (placeholder — backend ainda não tem is_primary)
            _sectionTitle('Moto principal'),
            const SizedBox(height: 8),
            _card(
              child: Row(
                children: [
                  const Icon(Icons.motorcycle, color: Color(0xFFFF0000), size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Sem moto principal',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Viagem em andamento (prioridade visual — spec §4)
            if (trips.hasActiveTrip) ...[
              _sectionTitle('Viagem em andamento'),
              const SizedBox(height: 8),
              _activeTripCard(context, trips),
              const SizedBox(height: 24),
            ] else ...[
              _sectionTitle('Comece uma viagem'),
              const SizedBox(height: 8),
              _startTripCard(context),
              const SizedBox(height: 24),
            ],

            // Eventos (placeholder)
            _sectionTitle('Eventos próximos'),
            const SizedBox(height: 8),
            _card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Nenhum evento próximo',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // SOS global
            SosButton(
              expanded: true,
              label: 'SOS — EMERGÊNCIA',
              onConfirm: () => _triggerSos(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: child,
            ),
          ),
        ),
      );

  Widget _activeTripCard(BuildContext context, TripProvider trips) {
    final trip = trips.activeTrip!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFB30000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.title?.toUpperCase() ?? 'VIAGEM',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _stat('${trips.currentDistanceKm.toStringAsFixed(0)} km',
                    'percorridos'),
                const SizedBox(width: 24),
                _stat(
                    '${(trips.movingSeconds ~/ 60).toString().padLeft(2, '0')} min',
                    'em movimento'),
                const SizedBox(width: 24),
                _stat(
                    '${trips.currentSpeed.toStringAsFixed(0)} km/h', 'atual'),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TripTrackingScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF0000),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.navigation),
                label: const Text(
                  'CONTINUAR VIAGEM',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      );

  Widget _startTripCard(BuildContext context) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF0000), width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TripTrackingScreen(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill,
                      color: Color(0xFFFF0000), size: 42),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'INICIAR VIAGEM',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),
        ),
      );

  void _triggerSos(BuildContext context) {
    // MVP: ainda não há endpoint /api/sos (gap do backend).
    // Apenas exibe feedback visual.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS acionado (endpoint /api/sos ainda não implementado no backend)'),
        backgroundColor: Color(0xFFFF0000),
        duration: Duration(seconds: 4),
      ),
    );
  }
}
