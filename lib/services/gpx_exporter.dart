import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/trip.dart';
import 'api_service.dart';
import 'app_logger.dart';

/// Serviço de exportação de viagens no formato GPX.
///
/// GPX (GPS Exchange Format) é o padrão universal aceito por:
/// - Garmin Connect
/// - Strava
/// - Komoot
/// - RideWithGPS
/// - Google Earth
/// - e muitos outros
class GpxExporter {
  GpxExporter._();
  static final GpxExporter instance = GpxExporter._();

  /// Busca os pontos da viagem do servidor e gera um arquivo GPX.
  /// Retorna o caminho do arquivo gerado.
  Future<String> exportTrip(Trip trip) async {
    AppLogger.log('GPX', 'Exportando viagem ${trip.id}...');

    // Busca todos os pontos da viagem do servidor
    final data = await ApiService.instance.getTripDetails(trip.id, pointsLimit: 100000);
    final points = data['points'] as List? ?? [];

    AppLogger.log('GPX', '${points.length} pontos recebidos do servidor');

    if (points.isEmpty) {
      throw Exception('Viagem sem pontos GPS. Não é possível exportar.');
    }

    // Gera o XML GPX
    final gpx = _buildGpx(trip, points);

    // Salva em arquivo no diretório temporário
    final dir = await getTemporaryDirectory();
    final safeName = _sanitizeFileName(trip.title ?? 'viagem_${trip.id}');
    final fileName = 'motohead_${safeName}_${trip.id}.gpx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(gpx);

    AppLogger.log('GPX', 'Arquivo gerado: ${file.path} (${gpx.length} bytes)');

    return file.path;
  }

  /// Exporta a viagem e abre o dialog de compartilhamento.
  Future<void> exportAndShare(Trip trip) async {
    try {
      final filePath = await exportTrip(trip);
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Viagem: ${trip.title ?? "MotoHead"}',
        text: 'Rota exportada do MotoHead — ${trip.distanceFormatted}, ${trip.durationFormatted}',
      );
    } catch (e) {
      AppLogger.error('GPX', 'Erro ao exportar: $e');
      rethrow;
    }
  }

  /// Gera o XML GPX no padrão Garmin/Strava.
  String _buildGpx(Trip trip, List<dynamic> points) {
    final buffer = StringBuffer();

    // Cabeçalho GPX 1.1
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<gpx version="1.1" creator="MotoHead" xmlns="http://www.topografix.com/GPX/1/1"');
    buffer.writeln(
        '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    buffer.writeln(
        '  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">');

    // Metadados
    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_escapeXml(trip.title ?? 'Viagem MotoHead')}</name>');
    if (trip.description != null && trip.description!.isNotEmpty) {
      buffer.writeln('    <desc>${_escapeXml(trip.description!)}</desc>');
    }
    buffer.writeln('    <time>${_toIso8601(trip.startTime)}</time>');
    buffer.writeln('  </metadata>');

    // Track (trk) — representa a rota percorrida
    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_escapeXml(trip.title ?? 'Viagem MotoHead')}</name>');
    buffer.writeln('    <type>motorcycle</type>');

    // Segmento de track (trkseg) — todos os pontos
    buffer.writeln('    <trkseg>');

    for (final p in points) {
      final lat = _parseDouble(p['latitude'] ?? p['lat']);
      final lng = _parseDouble(p['longitude'] ?? p['lng']);
      final ele = _parseDouble(p['altitude']);
      final speed = _parseDouble(p['speed']);
      final time = p['recorded_at']?.toString();

      if (lat == 0.0 && lng == 0.0) continue;

      buffer.writeln('      <trkpt lat="$lat" lon="$lng">');
      if (ele != null) {
        buffer.writeln('        <ele>$ele</ele>');
      }
      if (time != null && time.isNotEmpty) {
        buffer.writeln('        <time>${_toIso8601(time)}</time>');
      }
      // Speed em m/s (extensão GPX padrão Garmin)
      if (speed != null) {
        buffer.writeln(
            '        <extensions><gpxtpx:TrackPointExtension xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1">');
        buffer.writeln(
            '          <gpxtpx:speed>$speed</gpxtpx:speed>');
        buffer.writeln('        </gpxtpx:TrackPointExtension></extensions>');
      }
      buffer.writeln('      </trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');

    // Estatísticas resumidas como waypoints
    if (points.isNotEmpty) {
      final first = points.first;
      final last = points.last;
      final startLat = _parseDouble(first['latitude'] ?? first['lat']);
      final startLng = _parseDouble(first['longitude'] ?? first['lng']);
      final endLat = _parseDouble(last['latitude'] ?? last['lat']);
      final endLng = _parseDouble(last['longitude'] ?? last['lng']);

      // Waypoint de início
      if (startLat != null && startLng != null) {
        buffer.writeln('  <wpt lat="$startLat" lon="$startLng">');
        buffer.writeln('    <name>Início</name>');
        buffer.writeln('    <sym>Flag, Green</sym>');
        buffer.writeln('  </wpt>');
      }

      // Waypoint de fim
      if (endLat != null && endLng != null) {
        buffer.writeln('  <wpt lat="$endLat" lon="$endLng">');
        buffer.writeln('    <name>Fim</name>');
        buffer.writeln('    <sym>Flag, Red</sym>');
        buffer.writeln('  </wpt>');
      }
    }

    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Converte string para double, retornando null se inválido.
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Converte data do banco (YYYY-MM-DD HH:MM:SS) para ISO 8601 (YYYY-MM-DDTHH:MM:SSZ).
  String _toIso8601(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now().toUtc().toIso8601String();
    }
    try {
      final dt = DateTime.parse(dateStr);
      return dt.toUtc().toIso8601String();
    } catch (_) {
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  /// Escapa caracteres especiais XML.
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Sanitiza o nome do arquivo (remove caracteres inválidos).
  String _sanitizeFileName(String name) {
    final sanitized = name
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    return sanitized.length > 50 ? sanitized.substring(0, 50) : sanitized;
  }
}
