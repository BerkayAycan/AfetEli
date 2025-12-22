// lib/screens/common/profile_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Controller
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  
  // To change password
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  String _email = "";

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  // 1-) Get the data from database(Supabase)
  Future<void> _getProfile() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        _email = user.email ?? "";
        final data = await supabase.from('users').select().eq('id', user.id).single();
        
        _firstNameController.text = data['first_name'] ?? "";
        _lastNameController.text = data['last_name'] ?? "";
        _phoneController.text = data['phone_number'] ?? "";
        _professionController.text = data['profession'] ?? "";
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2-) Update the user info
  Future<void> _updateInfo() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('users').update({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'profession': _professionController.text.trim(),
      }).eq('id', userId);

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi!"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3-) Change Password
  Future<void> _changePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen şifre alanlarını doldurun.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final email = supabase.auth.currentUser!.email!;

      // A) Firstly, control that actual password is true with entering acc
      await supabase.auth.signInWithPassword(
        email: email,
        password: _oldPasswordController.text,
      );

      // B) If password is true, change the password
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre başarıyla değiştirildi!"), backgroundColor: Colors.green));
        _oldPasswordController.clear();
        _newPasswordController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eski şifre hatalı veya işlem başarısız."), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4-) Log out
  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Hesabım"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading && _email.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile icon
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFF673AB7),
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(_email, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  // Section 1-) Personal Info
                  _buildSectionTitle("Kişisel Bilgiler"),
                  const SizedBox(height: 10),
                  _buildTextField("Ad", _firstNameController),
                  _buildTextField("Soyad", _lastNameController),
                  _buildTextField("Telefon", _phoneController),
                  _buildTextField("Meslek", _professionController),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateInfo,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF673AB7)),
                      child: const Text("Bilgileri Güncelle"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Section 2-) Security
                  _buildSectionTitle("Güvenlik"),
                  const SizedBox(height: 10),
                  _buildTextField("Eski Şifre", _oldPasswordController, isPassword: true),
                  _buildTextField("Yeni Şifre", _newPasswordController, isPassword: true),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                      child: const Text("Şifreyi Değiştir"),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Section 3-) Log out
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text("Çıkış Yap", style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}