// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart'; // Sabitler

// SAYFA IMPORTLARI (Hata buradaydı, şimdi düzeltildi)
import 'screens/auth/login_page.dart';
import 'screens/auth/role_choosing_page.dart';
import 'screens/auth/register_page.dart'; // <-- İŞTE BU SATIR EKSİKTİ VEYA HATALIYDI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: mySupabaseUrl,
    anonKey: mySupabaseKey,
  );

  runApp(const AfetEliApp());
}

final supabase = Supabase.instance.client;

class AfetEliApp extends StatelessWidget {
  const AfetEliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AfetEli',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(), // Artık bunu tanıyacak
        '/role_choose': (context) => const RoleChoosingPage(),
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    final session = supabase.auth.currentSession;
    if (session != null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/role_choose');
    } else {
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}