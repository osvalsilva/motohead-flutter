import 'package:flutter/material.dart';

/// Botão de SOS global (spec §15, §23).
///
/// Botão grande, alto contraste, com etapa de confirmação (spec §16).
/// Ao confirmar, chama [onConfirm] — quem chama decide o que fazer
/// (no MVP ainda não há endpoint /api/sos — gap do backend).
class SosButton extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool expanded;
  final String? label;

  const SosButton({
    super.key,
    required this.onConfirm,
    this.expanded = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Container(
      decoration: BoxDecoration(
        shape: expanded ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: expanded ? BorderRadius.circular(14) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: const Color(0xFFFF0000),
        shape: expanded
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
            : const CircleBorder(),
        child: InkWell(
          onTap: () => _confirm(context),
          customBorder: expanded
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))
              : const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(expanded ? 18 : 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(height: 4),
                Text(
                  label ?? 'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: expanded ? 18 : 16,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: btn);
    }
    return btn;
  }

  /// Etapa de confirmação (spec §16 — proteção contra acionamento acidental).
  void _confirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF0000)),
            SizedBox(width: 8),
            Text('EMERGÊNCIA',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Deseja acionar o SOS?\n\n'
          'Sua localização será compartilhada com seus contatos de emergência.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMAR SOS'),
          ),
        ],
      ),
    );
  }
}
