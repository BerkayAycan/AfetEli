import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Hiding the backward button
      ),
      body: ListView(
        children: [
          _buildSettingItem(Icons.dark_mode, "Tema Ayarları", "Karanlık Mod"),
          _buildSettingItem(Icons.notifications, "Bildirimler", "Açık"),
          _buildSettingItem(Icons.language, "Dil", "Türkçe"),
          _buildSettingItem(Icons.info, "Uygulama Hakkında", "v1.0.0"),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {}, // currently empty
    );
  }
}