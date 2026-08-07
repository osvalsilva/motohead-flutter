import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Logo do MotoHead — estilizado em vermelho com a silhueta de moto.
/// Versão simples em texto + ícone para o MVP.
class MotoHeadLogo extends StatelessWidget {
  final double size;
  const MotoHeadLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.motorcycle,
          size: size,
          color: const Color(0xFFFF0000),
        ),
        const SizedBox(height: 8),
        Text(
          AppConfig.appName.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}
