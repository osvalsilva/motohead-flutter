import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/trip_provider.dart';
import '../providers/friend_provider.dart';
import '../services/api_service.dart';
import '../services/app_logger.dart';
import '../widgets/sos_button.dart';

/// Tela de Tracking (spec §7) — extremamente limpa.
///
/// Prioridade:
/// 1. mapa (placeholder — exige API key do Google Maps)
/// 2. posição atual
/// 3. rota
/// 4. informações essenciais
/// 5. controles de viagem
/// 6. SOS
class TripTrackingScreen extends StatefulWidget {
  const TripTrackingScreen({super.key});

  @override
  State<TripTrackingScreen> createState() => _TripTrackingScreenState();
}

class _TripTrackingScreenState extends State<TripTrackingScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _tripPhotos = [];

  @override
  Widget build(BuildContext context) {
    final trips = context.watch<TripProvider>();
    final hasActive = trips.hasActiveTrip || trips.paused;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        bottom: true,
        child: !hasActive
            ? _NoTripView(onStart: () => _showStartDialog(context, trips))
            : Column(
                children: [
                  // Mapa (placeholder — spec §7: prioridade 1)
                  Expanded(
                    flex: 3,
                    child: _MapPlaceholder(trips: trips),
                  ),
                  // Painel inferior — info + controles (spec §7)
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF121212),
                      border: Border(
                        top: BorderSide(color: Color(0xFFFF0000), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título da viagem
                        Text(
                          trips.activeTrip?.title?.toUpperCase() ??
                              'VIAGEM',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Linha 1: distância + duração (spec §7)
                        Row(
                          children: [
                            _stat('${trips.currentDistanceKm.toStringAsFixed(0)}',
                                'km percorridos'),
                            const SizedBox(width: 30),
                            _stat(
                                '${(trips.totalDurationSeconds ~/ 3600).toString().padLeft(2, '0')}:'
                                '${((trips.totalDurationSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}',
                                'duração'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Linha 2: velocidade atual + média (spec §7)
                        Row(
                          children: [
                            _stat(
                                '${trips.currentSpeed.toStringAsFixed(0)}',
                                'km/h atual'),
                            const SizedBox(width: 30),
                            _stat(
                                '${trips.activeTrip?.avgSpeed?.toStringAsFixed(0) ?? "—"}',
                                'km/h média'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Botões grandes (spec §24: botões grandes, alto contraste)
                        if (trips.paused)
                          _bigButton(
                            icon: Icons.play_arrow,
                            label: 'RETOMAR VIAGEM',
                            color: const Color(0xFFFF0000),
                            onTap: trips.resume,
                          )
                        else
                          _bigButton(
                            icon: Icons.pause,
                            label: 'PAUSAR VIAGEM',
                            color: Colors.orange,
                            onTap: trips.pause,
                          ),
                        const SizedBox(height: 12),
                        _bigButton(
                          icon: Icons.stop,
                          label: 'FINALIZAR VIAGEM',
                          color: Colors.white,
                          textColor: const Color(0xFFFF0000),
                          onTap: () => _confirmFinish(context, trips),
                        ),
                        const SizedBox(height: 16),
                        // SOS (spec §7: prioridade 6)
                        SosButton(
                          expanded: true,
                          label: 'SOS — EMERGÊNCIA',
                          onConfirm: () => _triggerSos(context, trips),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Future<void> _triggerSos(BuildContext context, TripProvider trips) async {
    // Enviar SOS para amigos
    final success = await context.read<FriendProvider>().sendSos();
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS enviado para seus contatos de emergência!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar SOS. Tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _confirmFinish(BuildContext context, TripProvider trips) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Finalizar viagem?',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Distância',
                '${trips.currentDistanceKm.toStringAsFixed(2)} km'),
            _row('Tempo total',
                '${(trips.totalDurationSeconds ~/ 3600).toString().padLeft(2, '0')}h'
                '${((trips.totalDurationSeconds % 3600) ~/ 60).toString().padLeft(2, '0')}min'),
            const SizedBox(height: 16),
            const Text('Nome da viagem (opcional):',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ex.: Serra da Canastra',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF0000)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSaveOptions(context, trips, name: nameCtrl.text.trim());
            },
            child: const Text('SALVAR',
                style: TextStyle(color: Color(0xFFFF0000))),
          ),
        ],
      ),
    );
  }

  void _showSaveOptions(BuildContext context, TripProvider trips, {String? name}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Salvar viagem',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Deseja adicionar fotos à viagem?',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _pickPhoto(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('ADICIONAR FOTO'),
            ),
            if (_tripPhotos.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Fotos selecionadas:',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tripPhotos.map((photo) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          photo,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _tripPhotos.remove(photo);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _finishTrip(context, trips, name: name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _tripPhotos.add(File(image.path));
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finishTrip(BuildContext context, TripProvider trips, {String? name}) async {
    final ok = await trips.finish(name: name);
    if (ok && context.mounted) {
      Navigator.pop(context); // volta para a lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viagem finalizada e sincronizada!'),
          backgroundColor: Colors.green,
        ),
      );
      // TODO: Enviar fotos para o servidor
    }
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.white54)),
            Text(v,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  void _showStartDialog(BuildContext context, TripProvider trips) {
    // Inicia viagem diretamente sem pedir nome — o nome será solicitado ao finalizar
    // Usa microtask para evitar crash se o dialog de permissão recriar a Activity
    trips.startTrip(name: '').then((success) {
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trips.error ?? 'Não foi possível iniciar a viagem.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        trips.clearError();
      }
    }).catchError((e) {
      AppLogger.error('TRACKING', 'Erro não tratado ao iniciar viagem: $e');
    });
  }
}

class _NoTripView extends StatelessWidget {
  final VoidCallback onStart;
  const _NoTripView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined,
                size: 80, color: Color(0xFFFF0000)),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma viagem ativa',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicie uma viagem para ver o tracking em tempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('INICIAR VIAGEM',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mapa com OpenStreetMap mostrando a rota percorrida em tempo real.
/// Centraliza automaticamente na posição real do GPS.
class _MapPlaceholder extends StatefulWidget {
  final TripProvider trips;
  const _MapPlaceholder({required this.trips});

  @override
  State<_MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<_MapPlaceholder> {
  final MapController _mapController = MapController();
  LatLng? _lastCenter;

  @override
  void didUpdateWidget(_MapPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Centraliza o mapa na posição real do GPS quando ela muda
    final lat = widget.trips.lastLat;
    final lng = widget.trips.lastLng;
    if (lat != null && lng != null) {
      final newCenter = LatLng(lat, lng);
      if (_lastCenter == null ||
          _haversine(_lastCenter!, newCenter) > 20) {
        // Só move se mudou mais de 20m (evita jitter)
        _lastCenter = newCenter;
        try {
          _mapController.move(newCenter, _mapController.camera.zoom);
        } catch (_) {
          // Mapa ainda não inicializado
        }
      }
    }
  }

  double _haversine(LatLng a, LatLng b) {
    const double r = 6371000;
    final dLat = (b.latitude - a.latitude) * (3.14159265359 / 180);
    final dLng = (b.longitude - a.longitude) * (3.14159265359 / 180);
    final x = dLat / 2;
    final y = dLng / 2;
    final h = x * x +
        y * y *
            (dLat / 2) *
            (dLat / 2); // simplificado — suficiente para threshold
    return r * 2 * (h > 1 ? 1 : h);
  }

  @override
  Widget build(BuildContext context) {
    final trips = widget.trips;
    final center = trips.lastLat != null && trips.lastLng != null
        ? LatLng(trips.lastLat!, trips.lastLng!)
        : const LatLng(-22.9769, -49.8686);

    return Container(
      color: const Color(0xFF0A0A0A),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
              keepAlive: true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.motohead.app',
              ),
              // Linha da rota percorrida
              if (trips.routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trips.routePoints,
                      color: const Color(0xFFFF0000),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              // Marcador da posição atual
              if (trips.lastLat != null && trips.lastLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(trips.lastLat!, trips.lastLng!),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFFF0000),
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Indicador de status
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trips.paused ? Icons.pause_circle : Icons.radio_button_checked,
                    color: trips.paused ? Colors.orange : const Color(0xFFFF0000),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trips.paused ? 'Pausado' : 'Gravando',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          // Contador de tempo e distância em tempo real sobre o mapa
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDuration(trips.totalDurationSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${trips.currentDistanceKm.toStringAsFixed(2)} km',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}


