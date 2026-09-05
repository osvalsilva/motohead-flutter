import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Sistema de logs do app — captura erros, falhas e exceções.
///
/// Salva os logs:
/// 1. Em memória (visualizáveis na tela de Logs)
/// 2. Em arquivo no dispositivo — `logs/motohead.log` (append imediato,
///    com debounce de ~500ms). Ao iniciar uma nova sessão, o log anterior
///    é rotacionado para `logs/motohead_prev.log` — assim, se o app
///    fechar/crashar, o log da sessão que crashou continua disponível.
/// 3. No servidor (POST /api/logs) — inclui a sessão anterior e o
///    crash nativo (Java/Kotlin), se houver.
class AppLogger {
  static final AppLogger _instance = AppLogger._();
  static AppLogger get instance => _instance;
  AppLogger._();

  static const _maxLines = 2000;
  static const _logFileName = 'motohead.log';
  static const _prevLogFileName = 'motohead_prev.log';
  static const _nativeChannel = MethodChannel('motohead/native');

  final List<String> _logs = [];
  final _controller = StreamController<List<String>>.broadcast();
  Stream<List<String>> get logStream => _controller.stream;

  /// Token JWT para enviar logs ao servidor (setado pelo AuthProvider).
  String? _token;
  set token(String? value) => _token = value;

  /// Timer para auto-save de logs em arquivo.
  Timer? _autoSaveTimer;

  // ---- Persistência em arquivo ----
  File? _logFile;
  bool _fileReady = false;
  final List<String> _pendingWrites = [];
  Timer? _flushTimer;

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

  /// Prepara o arquivo de log: rotaciona a sessão anterior para
  /// `motohead_prev.log` e cria o arquivo da sessão atual.
  /// Chamar uma vez no main() — não bloqueia o app.
  static Future<void> initFile() async {
    try {
      final file = await _sessionLogFile();
      final prev = File('${file.parent.path}/$_prevLogFileName');

      // Rotaciona: log anterior vira "prev" (mantém o log da sessão
      // que crashou para upload posterior)
      if (await file.exists()) {
        if (await prev.exists()) await prev.delete();
        await file.rename(prev.path);
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(
          '=== MotoHead v${AppConfig.appVersion} — sessão iniciada em ${DateTime.now().toIso8601String()} ===\n');

      instance._logFile = file;
      instance._fileReady = true;

      // Descarrega o que foi logado antes do arquivo ficar pronto
      if (instance._pendingWrites.isNotEmpty) {
        final pending = instance._pendingWrites.join('\n');
        instance._pendingWrites.clear();
        await file.writeAsString(pending, mode: FileMode.append);
      }
    } catch (e) {
      debugPrint('AppLogger.initFile erro: $e');
    }
  }

  static Future<File> _sessionLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${dir.path}/logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    return File('${logsDir.path}/$_logFileName');
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

    // Persiste em arquivo com debounce curto — em crash nativo, o que
    // foi logado há menos de ~500ms pode se perder, o resto não.
    _pendingWrites.add(line);
    if (stack != null) _pendingWrites.add('  Stack: $stack');
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushTimer != null) return;
    _flushTimer = Timer(const Duration(milliseconds: 500), () {
      _flushTimer = null;
      _flushToFile();
    });
  }

  Future<void> _flushToFile() async {
    if (_pendingWrites.isEmpty) return;
    final lines = _pendingWrites.join('\n');
    _pendingWrites.clear();
    try {
      if (_fileReady && _logFile != null) {
        await _logFile!.writeAsString('$lines\n', mode: FileMode.append);
      }
      // Se o arquivo ainda não está pronto, as linhas ficam em
      // _pendingWrites até o initFile() descarregá-las.
    } catch (_) {
      // Falha de disco não deve derrubar o app
    }
  }

  /// Retorna todos os logs em memória.
  List<String> get logs => List.unmodifiable(_logs);

  /// Lê o log da sessão anterior (rotacionado no boot) — útil para
  /// diagnosticar crashes: a sessão que fechou de forma anormal.
  static Future<String?> readPreviousSession() async {
    try {
      final file = await _sessionLogFile();
      final prev = File('${file.parent.path}/$_prevLogFileName');
      if (await prev.exists()) {
        final content = await prev.readAsString();
        return content.isEmpty ? null : content;
      }
    } catch (_) {}
    return null;
  }

  /// Lê o crash nativo (Java/Kotlin) capturado pelo handler no MainActivity.
  /// Retorna null se não houver crash pendente.
  static Future<String?> readNativeCrash() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await _nativeChannel.invokeMethod<String>('readNativeCrash');
    } catch (_) {
      return null;
    }
  }

  /// Limpa o crash nativo já enviado.
  static Future<void> clearNativeCrash() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _nativeChannel.invokeMethod('clearNativeCrash');
    } catch (_) {}
  }

  /// Monta o payload de device info para o upload.
  Map<String, dynamic> _deviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'app_version': AppConfig.appVersion,
      'logs_count': _logs.length,
      'locale': Platform.localeName,
    };
  }

  /// Envia os logs para o servidor (POST /api/logs).
  ///
  /// [includePrevious]: inclui o log da sessão anterior e o crash nativo,
  /// se existirem (usado no auto-upload pós-crash).
  /// Retorna true se enviado com sucesso.
  Future<bool> uploadToServer({bool includePrevious = false}) async {
    if (_logs.isEmpty && !includePrevious) return false;
    if (_token == null || _token!.isEmpty) return false;

    try {
      // Garante que tudo em memória foi persistido antes de enviar
      await _flushToFile();

      final allLogs = <String>[..._logs];

      if (includePrevious) {
        final prev = await readPreviousSession();
        if (prev != null && prev.isNotEmpty) {
          allLogs.add('===== SESSÃO ANTERIOR (possível crash) =====');
          allLogs.addAll(prev.split('\n'));
          allLogs.add('===== FIM SESSÃO ANTERIOR =====');
        }
        final crash = await readNativeCrash();
        if (crash != null && crash.isNotEmpty) {
          allLogs.add('===== CRASH NATIVO (Java/Kotlin) =====');
          allLogs.addAll(crash.split('\n'));
          allLogs.add('===== FIM CRASH NATIVO =====');
        }
      }

      if (allLogs.isEmpty) return false;

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
          'device_info': _deviceInfo(),
          'logs': allLogs,
        }),
      ).timeout(const Duration(seconds: 20));

      final ok = resp.statusCode >= 200 && resp.statusCode < 300;
      if (!ok) {
        // Loga a falha direto no arquivo (evita recursão de upload)
        await _appendDirect(
            '[${DateTime.now().toIso8601String()}] ERROR [LOGGER]: upload falhou — HTTP ${resp.statusCode}: ${resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body}');
      } else if (includePrevious) {
        await clearNativeCrash();
      }
      return ok;
    } catch (e) {
      await _appendDirect(
          '[${DateTime.now().toIso8601String()}] ERROR [LOGGER]: upload falhou — $e');
      return false;
    }
  }

  /// Auto-upload do log da sessão anterior + crash nativo, se houver.
  /// Fire-and-forget — chamado após restaurar/login da sessão.
  Future<void> autoUploadPreviousSession() async {
    if (_token == null || _token!.isEmpty) return;
    try {
      final prev = await readPreviousSession();
      final crash = await readNativeCrash();
      if ((prev == null || prev.isEmpty) && (crash == null || crash.isEmpty)) {
        return; // Nada para enviar
      }
      AppLogger.log('LOGGER',
          'autoUpload: sessão anterior detectada (prev=${prev != null}, crash=${crash != null}) — enviando...');
      final ok = await uploadToServer(includePrevious: true);
      AppLogger.log('LOGGER', 'autoUpload: resultado=$ok');
    } catch (e) {
      await _appendDirect(
          '[${DateTime.now().toIso8601String()}] ERROR [LOGGER]: autoUpload falhou — $e');
    }
  }

  /// Append direto no arquivo (usado para logar falhas do próprio logger
  /// sem passar pela memória/fluxo normal).
  Future<void> _appendDirect(String line) async {
    try {
      if (_fileReady && _logFile != null) {
        await _logFile!.writeAsString('$line\n', mode: FileMode.append);
      }
    } catch (_) {}
  }

  /// Salva os logs em arquivo no dispositivo (snapshot com timestamp).
  Future<String> saveToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      final file = File('${logsDir.path}/motohead_${DateTime.now().millisecondsSinceEpoch}.txt');
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

  /// Inicia auto-flush de logs a cada 30 segundos.
  void startAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _flushToFile();
    });
  }

  /// Para auto-save de logs.
  void stopAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  void dispose() {
    stopAutoSave();
    _flushTimer?.cancel();
    _controller.close();
  }
}
