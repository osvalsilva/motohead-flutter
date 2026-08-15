import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Sistema de logs do app — captura erros, falhas e exceções.
///
/// Salva os logs:
/// 1. Em memória (visualizáveis na tela de Logs)
/// 2. No servidor (POST /api/logs) — acessível remotamente
/// 3. Em arquivo no dispositivo (opcional)
class AppLogger {
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;
  AppLogger._();

  static const _maxLines = 2000;
  final List<String> _logs = [];
  final _controller = StreamController<List<String>>.broadcast();
  Stream<List<String>> get logStream => _controller.stream;

  /// Token JWT para enviar logs ao servidor (setado pelo AuthProvider).
  String? _token;
  set token(String? value) => _token = value;

  /// Inicializa o capturador de erros globais.
  /// Deve ser chamado no main() antes de runApp().
  static void init() {
    // Captura erros do framework Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      instance._log('FLUTTER ERROR', details.exceptionAsString(),
          stack: details.stack?.toString());
      FlutterError.presentError(details);
    };

    // Captura erros assíncronos não tratados (Zone errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      instance._log('PLATFORM ERROR', error.toString(), stack: stack.toString());
      return true;
    };

    // Captura erros de isolates
    Isolate.current.addErrorListener(RawReceivePort((dynamic data) {
      final list = data as List;
      instance._log('ISOLATE ERROR', list[0].toString(), stack: list[1]?.toString());
    }).sendPort);
  }

  /// Log manual — pode ser chamado de qualquer lugar do app.
  static void log(String tag, String message, {String? stack}) {
    instance._log(tag, message, stack: stack);
  }

  /// Log de erro
  static void error(String tag, String message, {String? stack}) {
    instance._log('ERROR [$tag]', message, stack: stack);
  }

  /// Log de info
  static void info(String tag, String message) {
    instance._log('INFO [$tag]', message);
  }

  void _log(String tag, String message, {String? stack}) {
    final now = DateTime.now();
    final line = '[${now.toIso8601String()}] $tag: $message';
    _logs.add(line);
    if (stack != null) {
      _logs.add('  Stack: $stack');
    }

    // Mantém no máximo _maxLines
    if (_logs.length > _maxLines) {
      _logs.removeRange(0, _logs.length - _maxLines);
    }

    // Também imprime no console (debug)
    if (kDebugMode) {
      debugPrint(line);
      if (stack != null) debugPrint('  Stack: $stack');
    }

    _controller.add(List.from(_logs));
  }

  /// Retorna todos os logs em memória.
  List<String> get logs => List.unmodifiable(_logs);

  /// Envia os logs para o servidor (POST /api/logs).
  /// Retorna true se enviado com sucesso.
  Future<bool> uploadToServer() async {
    if (_logs.isEmpty) return false;
    if (_token == null || _token!.isEmpty) return false;

    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/logs');
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'app_version': AppConfig.appVersion,
          'device_info': {
            'platform': Platform.operatingSystem,
            'logs_count': _logs.length,
          },
          'logs': _logs,
        }),
      ).timeout(const Duration(seconds: 15));

      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      debugPrint('Erro ao enviar logs: $e');
      return false;
    }
  }

  /// Salva os logs em arquivo no dispositivo.
  /// Retorna o caminho do arquivo.
  Future<String> saveToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/motohead_logs.txt');
      final content = _logs.join('\n');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      return 'Erro ao salvar logs: $e';
    }
  }

  /// Limpa todos os logs.
  void clear() {
    _logs.clear();
    _controller.add([]);
  }
}
