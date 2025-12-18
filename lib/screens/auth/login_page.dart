import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Log in Function
  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Requesting to Supabase Auth service
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // If Login is success redirect to listener of main.dart automaticly.
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş Başarılı! Yönlendiriliyorsunuz...')),
        );

        Navigator.of(context).pushNamedAndRemoveUntil('/role_choose', (route) => false);
      }

    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message), // Shows the error message (Example : Wrong password)
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beklenmedik bir hata oluştu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), 
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //Header space
              const Text(
                'AfetEli',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // E-mail space
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  hintText: 'E-mail',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password space
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  hintText: 'Şifre',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7), // Mor renk
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Giriş Yap',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              // Register direction to Register page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hesabınız yok mu?", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('Kayıt Ol', style: TextStyle(color: Color(0xFF673AB7))),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}