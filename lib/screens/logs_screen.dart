import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/app_logger.dart';

/// Tela de logs do app — mostra erros, falhas e exceções capturadas.
///
/// Útil para diagnosticar crashes e problemas.
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<String> _logs = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logs = AppLogger.instance.logs;
    AppLogger.instance.logStream.listen((logs) {
      if (mounted) {
        setState(() => _logs = logs);
      }
    });
  }

  Future<void> _uploadToServer() async {
    setState(() => _saving = true);
    try {
      // Garante que o token do AuthProvider está no AppLogger
      final auth = context.read<AuthProvider>();
      AppLogger.instance.token = auth.token;

      final ok = await AppLogger.instance.uploadToServer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? 'Logs enviados ao servidor com sucesso!'
                : 'Falha ao enviar logs. Verifique sua conexão.'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _saveLogs() async {
    setState(() => _saving = true);
    try {
      final path = await AppLogger.instance.saveToFile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logs salvos em: $path'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('LOGS DO APP',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            )),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            tooltip: 'Limpar logs',
            onPressed: () {
              AppLogger.instance.clear();
              setState(() => _logs = []);
            },
          ),
          // Enviar ao servidor
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFFF0000)),
                  )
                : const Icon(Icons.cloud_upload, color: Color(0xFFFF0000)),
            tooltip: 'Enviar ao servidor',
            onPressed: _saving ? null : _uploadToServer,
          ),
          // Salvar em arquivo local
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white54),
            tooltip: 'Salvar em arquivo',
            onPressed: _saveLogs,
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bug_report, size: 64, color: Colors.white24),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum log registrado',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final line = _logs[index];
                final isError = line.contains('ERROR') ||
                    line.contains('FLUTTER ERROR') ||
                    line.contains('PLATFORM ERROR') ||
                    line.contains('ISOLATE ERROR');
                final isStack = line.startsWith('  Stack:');
                return Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.red.withOpacity(0.1)
                        : (isStack
                            ? Colors.white.withOpacity(0.03)
                            : const Color(0xFF1A1A1A)),
                    borderRadius: BorderRadius.circular(4),
                    border: isError
                        ? Border.all(color: Colors.red.withOpacity(0.3))
                        : null,
                  ),
                  child: SelectableText(
                    line,
                    style: TextStyle(
                      color: isError
                          ? Colors.redAccent
                          : (isStack ? Colors.white38 : Colors.white70),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
