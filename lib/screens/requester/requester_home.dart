// lib/screens/requester/requester_home.dart
import 'package:flutter/material.dart';

class RequesterHomepage extends StatelessWidget {
  const RequesterHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yardım Arayan Paneli")),
      body: const Center(child: Text("Burası Yardım İsteme Ekranı Olacak")),
    );
  }
}