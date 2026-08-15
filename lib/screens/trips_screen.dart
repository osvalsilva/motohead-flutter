import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/sos_button.dart';
import 'trip_tracking_screen.dart';
import 'trip_detail_screen.dart';

/// Tela "Viagem" — aba da bottom nav (spec §3, §13).
///
/// Mostra:
/// - Botão "Iniciar nova viagem" (se nenhuma ativa)
/// - Viagem ativa com atalho para o tracking
/// - Histórico resumido (spec §13)
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MINHAS VIAGENS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 18,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: () => trips.loadHistory(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF0000),
        onRefresh: () => trips.loadHistory(),
        child: trips.loading && trips.history.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF0000)))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (trips.hasActiveTrip) ...[
                    _ActiveTripBanner(trips: trips),
                    const SizedBox(height: 24),
                  ] else ...[
                    _StartButton(onTap: () => _showStartDialog(context, trips)),
                    const SizedBox(height: 24),
                  ],
                  if (trips.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        trips.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const _SectionTitle('HISTÓRICO'),
                  const SizedBox(height: 8),
                  if (trips.history.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Nenhuma viagem registrada.\nToque em "Iniciar viagem" para começar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      ),
                    )
                  else
                    ...trips.history.map((t) => _TripTile(trip: t)),
                ],
              ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SosButton(
          onConfirm: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SOS acionado (endpoint /api/sos pendente no backend)'),
                backgroundColor: Color(0xFFFF0000),
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showStartDialog(BuildContext context, TripProvider trips) {
    // Inicia viagem diretamente sem pedir nome — o nome será solicitado ao finalizar
    trips.startTrip(name: '').then((ok) {
      if (ok && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TripTrackingScreen(),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trips.error ?? 'Falha ao iniciar viagem'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}

class _ActiveTripBanner extends StatelessWidget {
  final TripProvider trips;
  const _ActiveTripBanner({required this.trips});

  @override
  Widget build(BuildContext context) {
    final trip = trips.activeTrip!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFB30000)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripTrackingScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(trips.paused ? Icons.pause_circle : Icons.play_circle_fill,
                        color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      trips.paused ? 'PAUSADA' : 'EM ANDAMENTO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  trip.title ?? 'Viagem',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _stat('${trips.currentDistanceKm.toStringAsFixed(0)} km',
                        'percorridos'),
                    const SizedBox(width: 22),
                    _stat(
                        '${(trips.movingSeconds ~/ 60).toString().padLeft(2, '0')} min',
                        'movimento'),
                    const SizedBox(width: 22),
                    _stat(
                        '${trips.currentSpeed.toStringAsFixed(0)} km/h',
                        'atual'),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white70, size: 16),
                    SizedBox(width: 6),
                    Text('Toque para abrir o tracking',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String v, String l) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );
}

class _StartButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StartButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF0000), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.play_circle_fill,
                    color: Color(0xFFFF0000), size: 42),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'INICIAR NOVA VIAGEM',
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
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );
}

class _TripTile extends StatelessWidget {
  final Trip trip;
  const _TripTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateStr = trip.createdAt != null
        ? _formatDate(trip.createdAt!)
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            // Abre a página de detalhes com mapa e traçado da rota
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDetailScreen(trip: trip),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: const TextStyle(
                                color: Color(0xFFFF0000),
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        trip.title ?? 'Viagem sem nome',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trip.distanceFormatted} • ${trip.durationFormatted}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _statusChip(trip.status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String s) {
    try {
      final dt = DateTime.parse(s);
      return '${dt.day.toString().padLeft(2, '0')} ${const ['', 'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'][dt.month]}';
    } catch (_) {
      return '';
    }
  }

  Widget _statusChip(String status) {
    final map = {
      'active': ('ATIVA', Color(0xFFFF0000)),
      'paused': ('PAUSADA', Colors.orange),
      'completed': ('OK', Colors.green),
      'cancelled': ('CANCELADA', Colors.white24),
      'planning': ('PLANEJADA', Colors.white38),
      'imported': ('IMPORTADA', Colors.blueAccent),
    };
    final (label, color) = map[status] ?? ('?', Colors.white38);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
