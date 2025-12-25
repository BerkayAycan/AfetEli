import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controller
  final _firstNameController = TextEditingController(); 
  final _lastNameController = TextEditingController();  
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Emergency Person
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Variable
  String? _selectedProfession; 
  bool _isLoading = false;
  
  // Privacy Policy Boxes
  bool _kvkkAccepted = false;
  bool _dataProcessingAccepted = false;
  bool _termsAccepted = false;

  // Occupation List
  final List<String> _professions = [
    'Doktor',
    'Hemşire',
    'Mühendis',
    'Öğretmen',
    'Arama Kurtarma Personeli',
    'Öğrenci',
    'Diğer'
  ];

  // Register Function
  Future<void> _signUp() async {
    // 1-) Basic Controller
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor!")));
      return;
    }
    if (!_kvkkAccepted || !_dataProcessingAccepted || !_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm sözleşmeleri onaylayın.")));
      return;
    }
    if (_selectedProfession == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen mesleğinizi seçin.")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // 2-)  Create a user with Supabase Auth 
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = res.user;

      if (user != null) {
        // 3-) Saving detailed Info's to 'users' table
        await supabase.from('users').insert({
          'id': user.id,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'profession': _selectedProfession,
          'emergency_contact_name': _emergencyNameController.text.trim(),
          'emergency_contact_phone': _emergencyPhoneController.text.trim(),
          'emergency_contact_relation': _emergencyRelationController.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt Başarılı! Giriş yapabilirsiniz.')),
          );
          Navigator.pop(context); // Return Register Page
        }
      }
    } on AuthException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message), backgroundColor: Colors.red));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $error'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // DESIGN WIDGETS
  
  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    bool isPassword = false,
    IconData? icon
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[800], 
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixIcon: icon != null ? Icon(icon, color: Colors.grey) : null, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Accept Box Design
  Widget _buildCheckboxRow(String text, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value, 
          onChanged: onChanged,
          activeColor: const Color(0xFF673AB7), // Mor renk
          checkColor: Colors.white,
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header seems like Tab Bar on top
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Giriş", style: TextStyle(color: Colors.grey)))),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0), 
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Center(child: Text("Kayıt ol", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // PERSONAL INFOS
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _firstNameController, hint: "Ad", icon: Icons.cancel_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(controller: _lastNameController, hint: "Soyad", icon: Icons.cancel_outlined)),
              ],
            ),
            _buildTextField(controller: _emailController, hint: "e-mail", icon: Icons.cancel_outlined),
            _buildTextField(controller: _phoneController, hint: "Telefon Numarası", icon: Icons.cancel_outlined),
            _buildTextField(controller: _passwordController, hint: "Şifre", isPassword: true, icon: Icons.cancel_outlined),
            _buildTextField(controller: _confirmPasswordController, hint: "Şifre Onayı", isPassword: true, icon: Icons.cancel_outlined),

            const SizedBox(height: 10),
            const Text("Meslek", style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 5),
            
            // OCCUPATION DROPDOWN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedProfession,
                  hint: const Text("Meslek Seçiniz"),
                  isExpanded: true,
                  items: _professions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedProfession = newValue;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const Text("Afet Anında Ulaşılacak Kişi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // PERSON OF EMERGENCY
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _emergencyNameController, hint: "Ad Soyad", icon: Icons.cancel_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(controller: _emergencyPhoneController, hint: "Telefon", icon: Icons.cancel_outlined)),
              ],
            ),
            _buildTextField(controller: _emergencyRelationController, hint: "Yakınlık Derecesi (Örn. Anne)", icon: Icons.cancel_outlined),

            const SizedBox(height: 10),

            // CONFIRMATION BOX
            _buildCheckboxRow("Kişisel Verilerimin İşlenmesini Kabul Ediyorum", _dataProcessingAccepted, (v) => setState(() => _dataProcessingAccepted = v!)),
            _buildCheckboxRow("KVKK Aydınlatma Metni'ni onaylıyorum", _kvkkAccepted, (v) => setState(() => _kvkkAccepted = v!)),
            _buildCheckboxRow("Hizmet Şartları'nı onaylıyorum", _termsAccepted, (v) => setState(() => _termsAccepted = v!)),

            const SizedBox(height: 20),

            // REGISTER BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7), 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), 
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Kayıt Ol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}