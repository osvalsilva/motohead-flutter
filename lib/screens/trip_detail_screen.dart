import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import '../services/api_service.dart';

/// Tela de detalhes de uma viagem finalizada.
///
/// Mostra o mapa com o traçado completo da rota percorrida,
/// além das estatísticas geradas (distância, tempo, velocidade, etc.).
class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _loading = true;
  List<LatLng> _routePoints = [];
  String? _error;
  Trip? _updatedTrip;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await ApiService.instance.getTripDetails(widget.trip.id);
      final points = data['points'] as List? ?? [];
      setState(() {
        _routePoints = points.map<LatLng>((p) {
          // Banco usa latitude/longitude, não lat/lng
          final lat = (p['latitude'] != null)
              ? double.tryParse('${p['latitude']}') ?? 0.0
              : double.tryParse('${p['lat']}') ?? 0.0;
          final lng = (p['longitude'] != null)
              ? double.tryParse('${p['longitude']}') ?? 0.0
              : double.tryParse('${p['lng']}') ?? 0.0;
          return LatLng(lat, lng);
        }).where((p) => p.latitude != 0.0 || p.longitude != 0.0).toList();
        // Atualiza a trip com os dados completos
        _updatedTrip = Trip.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar detalhes: $e';
        _loading = false;
      });
    }
  }

  Trip get trip => _updatedTrip ?? widget.trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(
          trip.title?.isNotEmpty == true ? trip.title! : 'Viagem sem nome',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF0000)))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                )
              : Column(
                  children: [
                    // Mapa com o traçado da rota
                    Expanded(
                      flex: 3,
                      child: _RouteMap(points: _routePoints, trip: trip),
                    ),
                    // Painel com dados da viagem
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF121212),
                        border: Border(
                          top: BorderSide(color: Color(0xFFFF0000), width: 1),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Data da viagem
                          if (trip.createdAt != null)
                            Text(
                              _formatDate(trip.createdAt!),
                              style: const TextStyle(
                                color: Color(0xFFFF0000),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Título
                          Text(
                            trip.title?.isNotEmpty == true ? trip.title! : 'Viagem sem nome',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (trip.description != null && trip.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              trip.description!,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Estatísticas
                          Row(
                            children: [
                              _stat(trip.distanceFormatted, 'distância'),
                              const SizedBox(width: 20),
                              _stat(trip.durationFormatted, 'duração'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _stat(
                                trip.maxSpeed != null
                                    ? '${trip.maxSpeed!.toStringAsFixed(0)} km/h'
                                    : '—',
                                'vel. máxima',
                              ),
                              const SizedBox(width: 20),
                              _stat(
                                trip.avgSpeed != null
                                    ? '${trip.avgSpeed!.toStringAsFixed(0)} km/h'
                                    : '—',
                                'vel. média',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _stat('${_routePoints.length}', 'pontos GPS'),
                              const SizedBox(width: 20),
                              _stat(
                                _formatDuration(trip.movingSeconds),
                                'tempo em movimento',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  String _formatDate(String s) {
    try {
      final dt = DateTime.parse(s);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return s;
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

/// Mapa mostrando o traçado completo da rota percorrida.
class _RouteMap extends StatelessWidget {
  final List<LatLng> points;
  final Trip trip;

  const _RouteMap({required this.points, required this.trip});

  @override
  Widget build(BuildContext context) {
    // Centro do mapa: primeiro ponto da rota, ou coordenada inicial da trip
    final center = points.isNotEmpty
        ? points.first
        : (trip.startLat != null && trip.startLng != null
            ? LatLng(trip.startLat!, trip.startLng!)
            : const LatLng(-22.9769, -49.8686));

    // Zoom automático baseado no número de pontos
    final zoom = points.length > 100 ? 13.0 : points.length > 10 ? 15.0 : 16.0;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.motohead.app',
        ),
        // Linha da rota
        if (points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                color: const Color(0xFFFF0000),
                strokeWidth: 4.0,
              ),
            ],
          ),
        // Marcador de início
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: points.first,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.flag,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              // Marcador de fim
              Marker(
                point: points.last,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFF0000),
                  size: 36,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
