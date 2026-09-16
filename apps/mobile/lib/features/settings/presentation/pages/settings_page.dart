import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text(
          'Paramètres & Sécurité',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Chiffrement & Algorithmes'),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: 'Algorithme de chiffrement',
            subtitle: 'AES-256-GCM (Galois/Counter Mode)',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Actif',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          _buildSettingTile(
            icon: Icons.key_outlined,
            title: 'Dérivation de clé (KDF)',
            subtitle: 'PBKDF2 HMAC-SHA256 • 100 000 itérations',
          ),
          _buildSettingTile(
            icon: Icons.security,
            title: 'Contrôle d\'intégrité',
            subtitle: 'Tag MAC 128 bits + En-tête AAD authentifié',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Confidentialité locale'),
          _buildSettingTile(
            icon: Icons.memory,
            title: 'Traitement en mémoire sécurisée',
            subtitle: 'Les clés et clair ne sont jamais envoyés sur internet',
            trailing: const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
          ),
          _buildSettingTile(
            icon: Icons.sd_storage_outlined,
            title: 'Stockage local',
            subtitle: 'Historique persisté localement sur l\'appareil',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('À propos'),
          _buildSettingTile(
            icon: Icons.info_outline,
            title: 'Version de l\'application',
            subtitle: '1.0.0 (Groupe 18 - FileEncryptor)',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
