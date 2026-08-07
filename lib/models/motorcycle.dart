/// Modelo de Moto do usuário (tabela `motorcycles`).
class Motorcycle {
  final int id;
  final int userId;
  final String brand;
  final String model;
  final int year;
  final int cc;
  final String? nickname;
  final String? color;
  final String? plate;
  final String status;

  Motorcycle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.cc,
    this.nickname,
    this.color,
    this.plate,
    required this.status,
  });

  factory Motorcycle.fromJson(Map<String, dynamic> j) {
    return Motorcycle(
      id: (j['id'] as num).toInt(),
      userId: (j['user_id'] as num).toInt(),
      brand: j['brand'] as String? ?? '',
      model: j['model'] as String? ?? '',
      year: (j['year'] as num?)?.toInt() ?? 0,
      cc: (j['cc'] as num?)?.toInt() ?? 0,
      nickname: j['nickname'] as String?,
      color: j['color'] as String?,
      plate: j['plate'] as String?,
      status: j['status'] as String? ?? 'active',
    );
  }

  /// Nome amigável: apelido se houver, senão "Marca Modelo (Ano)".
  String get displayName {
    if (nickname != null && nickname!.trim().isNotEmpty) return nickname!;
    return '$brand $model ($year)';
  }

  @override
  String toString() => 'Motorcycle($displayName)';
}
