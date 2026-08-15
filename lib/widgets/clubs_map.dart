import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';

/// Mapa de clubes na página inicial.
///
/// Mostra os clubes como pontos vermelhos no mapa.
/// Ao tocar em um ponto, abre um popup com informações do clube.
class ClubsMap extends StatefulWidget {
  const ClubsMap({super.key});

  @override
  State<ClubsMap> createState() => _ClubsMapState();
}

class _ClubsMapState extends State<ClubsMap> {
  List<Map<String, dynamic>> _clubs = [];
  bool _loading = true;
  String? _error;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    try {
      // Carrega várias páginas para ter mais clubes no mapa
      final all = <Map<String, dynamic>>[];
      for (int p = 1; p <= 3; p++) {
        final clubs = await ApiService.instance.listClubs(page: p);
        all.addAll(clubs);
      }
      if (mounted) {
        setState(() {
          _clubs = all;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtra clubes com coordenadas válidas
    final validClubs = _clubs.where((c) {
      final lat = double.tryParse('${c['latitude'] ?? ''}');
      final lng = double.tryParse('${c['longitude'] ?? ''}');
      return lat != null && lng != null && lat != 0.0 && lng != 0.0;
    }).toList();

    // Centro do mapa — Brasil
    const defaultCenter = LatLng(-14.235, -51.9253);
    LatLng? firstClub;
    if (validClubs.isNotEmpty) {
      final lat = double.tryParse('${validClubs.first['latitude']}') ?? 0;
      final lng = double.tryParse('${validClubs.first['longitude']}') ?? 0;
      if (lat != 0 && lng != 0) firstClub = LatLng(lat, lng);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Aviso para o usuário
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF0000).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFF0000), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Toque em um ponto vermelho no mapa para ver os detalhes do clube',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Mapa
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 280,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF0000)),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Erro ao carregar clubes: $_error',
                            style: const TextStyle(color: Colors.white38),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: firstClub ?? defaultCenter,
                              initialZoom: 4.0,
                              keepAlive: true,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.motohead.app',
                              ),
                              // Pontos vermelhos dos clubes
                              MarkerLayer(
                                markers: validClubs.map((club) {
                                  final lat =
                                      double.tryParse('${club['latitude']}') ?? 0;
                                  final lng =
                                      double.tryParse('${club['longitude']}') ?? 0;
                                  return Marker(
                                    point: LatLng(lat, lng),
                                    width: 40,
                                    height: 40,
                                    child: GestureDetector(
                                      onTap: () => _showClubInfo(context, club),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFFF0000),
                                        size: 32,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          // Contador de clubes
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${validClubs.length} clubes',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  void _showClubInfo(BuildContext context, Map<String, dynamic> club) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Nome do clube
            Text(
              club['name'] ?? 'Clube',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Localização
            if (club['city'] != null || club['state'] != null)
              Row(
                children: [
                  const Icon(Icons.place, color: Color(0xFFFF0000), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${club['city'] ?? ''}${club['city'] != null && club['state'] != null ? ', ' : ''}${club['state'] ?? ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            // Descrição
            if (club['description'] != null &&
                club['description'].toString().isNotEmpty) ...[
              Text(
                club['description'],
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            // Presidente
            if (club['president_name'] != null &&
                club['president_name'].toString().isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.white38, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Presidente: ${club['president_name']}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Contato
            if (club['contact_email'] != null &&
                club['contact_email'].toString().isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.white38, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      club['contact_email'],
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (club['contact_phone'] != null &&
                club['contact_phone'].toString().isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white38, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    club['contact_phone'],
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Botão de fechar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('FECHAR',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
