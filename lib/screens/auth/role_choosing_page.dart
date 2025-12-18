// lib/screens/auth/role_choosing_page.dart

import 'package:flutter/material.dart';
// main.dart içindeki supabase nesnesine erişmek istiyorsan import etmelisin
// Ancak basit bir stateful widget şimdilik iş görür.

class RoleChoosingPage extends StatefulWidget {
  const RoleChoosingPage({super.key});

  @override
  State<RoleChoosingPage> createState() => _RoleChoosingPageState();
}

class _RoleChoosingPageState extends State<RoleChoosingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Rol Seçimi"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Geri butonunu gizle
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Hangi roldesiniz?",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Yardım Arayan Seçildi")),
                );
              },
              child: const Text("Yardım Arayan"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gönüllü Seçildi")),
                );
              },
              child: const Text("Gönüllü"),
            ),
          ],
        ),
      ),
    );
  }
}