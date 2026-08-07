import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';

/// Tela de Perfil (spec §21) — simplificada.
///
/// Mostra:
/// - foto (avatar com inicial)
/// - nome + email
/// - moto principal (placeholder)
/// - resumo de viagens
/// - configurações (placeholder)
/// - logout
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final trips = context.watch<TripProvider>();
    final user = auth.user;

    final totalTrips = trips.history.length;
    final completed = trips.history.where((t) => t.isCompleted).length;
    final totalKm = trips.history.fold<double>(
        0, (sum, t) => sum + t.distanceKm);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PERFIL',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            )),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Cabeçalho
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFFF0000),
                child: Text(
                  (user?.firstName.isNotEmpty ?? false)
                      ? user!.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '—',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                    if (user?.city != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${user!.city}${user.state != null ? " - ${user.state}" : ""}',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Resumo de viagens (spec §21)
          const _SectionTitle('RESUMO DE VIAGENS'),
          const SizedBox(height: 10),
          Row(
            children: [
              _statCard('VIAGENS', '$totalTrips'),
              const SizedBox(width: 12),
              _statCard('FINALIZADAS', '$completed'),
              const SizedBox(width: 12),
              _statCard('KM TOTAL', totalKm.toStringAsFixed(0)),
            ],
          ),
          const SizedBox(height: 28),

          // Moto principal (placeholder)
          const _SectionTitle('MOTO PRINCIPAL'),
          const SizedBox(height: 10),
          _listTile(
            icon: Icons.motorcycle,
            title: 'Sem moto principal',
            subtitle: 'Toque para configurar',
            onTap: () => _openUrl(context, '${AppConfig.apiBaseUrl}/motorcycles'),
          ),
          const SizedBox(height: 28),

          // Configurações (spec §21)
          const _SectionTitle('CONFIGURAÇÕES'),
          const SizedBox(height: 10),
          _listTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacidade',
            onTap: () => _openUrl(context, '${AppConfig.apiBaseUrl}/lgpd/privacy'),
          ),
          _listTile(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            onTap: () => _openUrl(context, '${AppConfig.apiBaseUrl}/notifications'),
          ),
          _listTile(
            icon: Icons.contact_emergency,
            title: 'Contatos de SOS',
            onTap: () => _showSosInfo(context),
          ),
          _listTile(
            icon: Icons.location_on_outlined,
            title: 'Permissões de localização',
            onTap: () => _showLocationInfo(context),
          ),
          _listTile(
            icon: Icons.settings_outlined,
            title: 'Configurações da viagem',
            onTap: () => _openUrl(context, '${AppConfig.apiBaseUrl}/settings'),
          ),
          const SizedBox(height: 28),

          // Versão
          Center(
            child: Text(
              '${AppConfig.appName} v${AppConfig.appVersion}',
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),

          // Logout
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context, auth, trips),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF0000),
                side: const BorderSide(color: Color(0xFFFF0000)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('SAIR',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10, letterSpacing: 1)),
            ],
          ),
        ),
      );

  Widget _listTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: ListTile(
              leading: Icon(icon, color: const Color(0xFFFF0000)),
              title: Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              subtitle: subtitle != null
                  ? Text(subtitle,
                      style: const TextStyle(color: Colors.white38, fontSize: 12))
                  : null,
              trailing:
                  const Icon(Icons.chevron_right, color: Colors.white24),
            ),
          ),
        ),
      );

  void _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível abrir: $url'),
          backgroundColor: const Color(0xFFFF0000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSosInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Configure contatos de emergência no site MotoHead'),
        backgroundColor: const Color(0xFFFF0000),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLocationInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Permita acesso à localização nas configurações do sistema'),
        backgroundColor: const Color(0xFFFF0000),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmLogout(
      BuildContext context, AuthProvider auth, TripProvider trips) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Sair?', style: TextStyle(color: Colors.white)),
        content: Text(
          trips.hasActiveTrip
              ? 'Você tem uma viagem em andamento. O tracking será interrompido localmente.'
              : 'Deseja realmente sair?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await trips.cancelLocal();
              await auth.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('SAIR'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      );
}
