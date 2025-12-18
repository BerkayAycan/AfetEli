// lib/screens/volunteer/volunteer_home.dart
import 'package:flutter/material.dart';

class VolunteerHomepage extends StatelessWidget {
  const VolunteerHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gönüllü Paneli")),
      body: const Center(child: Text("Burası Gönüllü Ekranı Olacak")),
    );
  }
}