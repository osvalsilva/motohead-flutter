import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';

import '../models/trip.dart';
import '../services/api_service.dart';
import '../services/app_logger.dart';
import '../services/gpx_exporter.dart';

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
  bool _exporting = false;
  bool _importing = false;
  List<LatLng> _routePoints = [];
  List<Map<String, dynamic>> _rawPoints = [];
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
        // Guarda pontos brutos para exportação GPX
        _rawPoints = points.cast<Map<String, dynamic>>();
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
        actions: [
          // Botão de exportar GPX
          IconButton(
            icon: _exporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFFF0000)),
                  )
                : const Icon(Icons.download, color: Color(0xFFFF0000)),
            tooltip: 'Exportar GPX (Garmin/Strava)',
            onPressed: _exporting ? null : _exportGpx,
          ),
        ],
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
              : SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Mapa com o traçado da rota
                    Expanded(
                      flex: 3,
                      child: _RouteMap(points: _routePoints, trip: trip),
                    ),
                    // Botão "Atualizar mapa" — carrega GPX do dispositivo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _importing ? null : _importGpx,
                          icon: _importing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Color(0xFFFF0000)),
                                )
                              : const Icon(Icons.upload_file, color: Color(0xFFFF0000)),
                          label: Text(
                            _importing ? 'Atualizando...' : 'Atualizar mapa via GPX',
                            style: const TextStyle(
                              color: Color(0xFFFF0000),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF0000)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Painel com dados da viagem
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

  Future<void> _exportGpx() async {
    setState(() => _exporting = true);
    try {
      await GpxExporter.instance.exportAndShare(trip);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  /// Abre o seletor de arquivos para escolher um GPX do dispositivo,
  /// envia ao servidor para atualizar os pontos da viagem e recarrega o mapa.
  Future<void> _importGpx() async {
    setState(() => _importing = true);
    try {
      // Seleciona arquivo GPX do dispositivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _importing = false);
        return;
      }

      final file = result.files.first;
      String gpxContent;

      if (file.bytes != null) {
        gpxContent = String.fromCharCodes(file.bytes!);
      } else if (file.path != null) {
        gpxContent = await _readFile(file.path!);
      } else {
        throw Exception('Não foi possível ler o arquivo');
      }

      if (gpxContent.isEmpty) {
        throw Exception('Arquivo GPX vazio');
      }

      AppLogger.log('GPX', 'Importando GPX: ${file.name} (${gpxContent.length} bytes)');

      // Envia ao servidor para atualizar a viagem
      final response = await ApiService.instance.updateTripFromGpx(
        trip.id,
        gpxContent,
      );

      final pointsCount = response['points'] ?? 0;
      AppLogger.log('GPX', 'Viagem atualizada com $pointsCount pontos');

      // Recarrega os detalhes da viagem
      await _loadDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mapa atualizado com $pointsCount pontos do GPX!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('GPX', 'Erro ao importar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar GPX: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _importing = false);
  }

  /// Lê um arquivo do caminho especificado.
  Future<String> _readFile(String path) async {
    final file = File(path);
    return await file.readAsString();
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
