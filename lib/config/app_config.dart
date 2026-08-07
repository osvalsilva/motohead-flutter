/// Configuração central do app MotoHead.
///
/// O emulador Android acessa o host (XAMPP) via 10.0.2.2 (alias do 127.0.0.1 do PC).
/// Em dispositivo físico, troque pelo IP da máquina na rede local (ex.: 192.168.0.10).
class AppConfig {
  AppConfig._();

  /// URL base da API MotoHead.
  /// - Emulador Android -> 10.0.2.2 (host)
  /// - Device físico    -> IP da máquina na LAN
  /// - Web/Windows      -> localhost
  static const String apiBaseUrl = 'https://motohead.com.br';

  /// Slogan do produto (spec §1).
  static const String slogan = 'Sua estrada. Nossa história.';

  /// Nome do app.
  static const String appName = 'MotoHead';

  /// Versão do app.
  static const String appVersion = '1.0.0';

  /// Intervalo (ms) entre pontos GPS durante uma viagem ativa.
  static const int trackingIntervalMs = 5000;

  /// Distância mínima (metros) para registrar um novo ponto.
  static const double trackingMinDistanceMeters = 10.0;
}
