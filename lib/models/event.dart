/// Modelo simplificado de Evento (spec §20).
class MotoEvent {
  final int id;
  final String title;
  final String? description;
  final String? eventDate;
  final String? location;
  final String type;
  final String status;
  final int? createdBy;
  final String? creatorName;
  final double? latitude;
  final double? longitude;

  MotoEvent({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    this.location,
    required this.type,
    required this.status,
    this.createdBy,
    this.creatorName,
    this.latitude,
    this.longitude,
  });

  factory MotoEvent.fromJson(Map<String, dynamic> j) {
    double? toDouble(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    return MotoEvent(
      id: (j['id'] as num).toInt(),
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      eventDate: j['event_date'] as String?,
      location: j['location'] as String?,
      type: j['type'] as String? ?? 'meeting',
      status: j['status'] as String? ?? 'scheduled',
      createdBy: j['created_by'] == null ? null : (j['created_by'] as num).toInt(),
      creatorName: j['creator_name'] as String?,
      latitude: toDouble(j['latitude']),
      longitude: toDouble(j['longitude']),
    );
  }

  /// Data curta DD/MM (spec §13).
  String get shortDate {
    if (eventDate == null) return '';
    try {
      final dt = DateTime.parse(eventDate!);
      return '${dt.day.toString().padLeft(2, '0')} ${_monthAbbr(dt.month)}';
    } catch (_) {
      return '';
    }
  }

  String _monthAbbr(int m) =>
      const ['', 'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ'][m];
}
