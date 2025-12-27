import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final _firstNameController = TextEditingController(); 
  final _lastNameController = TextEditingController(); 
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tcController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Variables
  String? _selectedProfession; 
  String? _selectedBloodType; // YENİ: Seçilen Kan Grubu
  bool _isLoading = false;
  
  // Privacy Policy Boxes
  bool _kvkkAccepted = false;
  bool _dataProcessingAccepted = false;
  bool _termsAccepted = false;

  // Lists
  final List<String> _professions = [
    'Doktor', 'Hemşire', 'Mühendis', 'Öğretmen', 
    'Arama Kurtarma Personeli', 'Öğrenci', 'Diğer'
  ];

  final List<String> _bloodTypes = [
    'A Rh+', 'A Rh-', 'B Rh+', 'B Rh-', 
    'AB Rh+', 'AB Rh-', '0 Rh+', '0 Rh-'
  ];

  Future<void> _signUp() async {
    // 1. Validations
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Şifreler uyuşmuyor!");
      return;
    }
    if (!_kvkkAccepted || !_dataProcessingAccepted || !_termsAccepted) {
      _showError("Lütfen tüm sözleşmeleri onaylayın.");
      return;
    }
    if (_selectedProfession == null) {
      _showError("Lütfen mesleğinizi seçin.");
      return;
    }
    if (_tcController.text.length != 11) {
      _showError("TC Kimlik No 11 haneli olmalıdır.");
      return;
    }
    if (_selectedBloodType == null) {
      _showError("Lütfen kan grubunuzu seçin.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // 2. Auth Sign Up
      final AuthResponse res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = res.user;

      if (user != null) {
        // 3. Save All Info to 'users' table
        await supabase.from('users').insert({
          'id': user.id,
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone_number': _phoneController.text.trim(),
          'profession': _selectedProfession,
          'tc_no': _tcController.text.trim(),
          'blood_type': _selectedBloodType,
          'address': _addressController.text.trim(),
          
          'emergency_contact_name': _emergencyNameController.text.trim(),
          'emergency_contact_phone': _emergencyPhoneController.text.trim(),
          'emergency_contact_relation': _emergencyRelationController.text.trim(),
          
          'role': 'user', 
          'volunteer_status': 'none',
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kayıt Başarılı! Giriş yapabilirsiniz.'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); 
        }
      }
    } on AuthException catch (error) {
      if (mounted) _showError(error.message);
    } catch (error) {
      if (mounted) _showError('Hata: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // Text Field Builder
  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    bool isPassword = false,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLines: maxLines,
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

  // Dropdown Builder
  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Checkbox Builder
  Widget _buildCheckboxRow(String text, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value, 
          onChanged: onChanged,
          activeColor: const Color(0xFF673AB7), 
          checkColor: Colors.white,
        ),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
            // Header
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
                      decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(25)),
                      child: const Center(child: Text("Kayıt ol", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Personal infos
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _firstNameController, hint: "Ad", icon: Icons.person)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(controller: _lastNameController, hint: "Soyad", icon: Icons.person)),
              ],
            ),
            
            // ID NO (TC)
            _buildTextField(
              controller: _tcController, 
              hint: "TC Kimlik No", 
              icon: Icons.badge,
              keyboardType: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)]
            ),

            _buildTextField(controller: _emailController, hint: "e-mail", icon: Icons.email, keyboardType: TextInputType.emailAddress),
            _buildTextField(controller: _phoneController, hint: "Telefon Numarası", icon: Icons.phone, keyboardType: TextInputType.phone),
            
            _buildTextField(controller: _passwordController, hint: "Şifre", isPassword: true, icon: Icons.lock),
            _buildTextField(controller: _confirmPasswordController, hint: "Şifre Onayı", isPassword: true, icon: Icons.lock),

            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Meslek", style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 5),
                      _buildDropdown("Seçiniz", _selectedProfession, _professions, (v) => setState(() => _selectedProfession = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Kan Grubu", style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 5),
                      _buildDropdown("Seç", _selectedBloodType, _bloodTypes, (v) => setState(() => _selectedBloodType = v)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            
            // Adress space
            const Text("Adres Bilgisi", style: TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 5),
            _buildTextField(
              controller: _addressController, 
              hint: "Tam adresinizi giriniz...", 
              maxLines: 3,
              icon: Icons.location_on
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const Text("Afet Anında Ulaşılacak Kişi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Person of emergeny
            Row(
              children: [
                Expanded(child: _buildTextField(controller: _emergencyNameController, hint: "Ad Soyad", icon: Icons.person_outline)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(controller: _emergencyPhoneController, hint: "Telefon", icon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
              ],
            ),
            _buildTextField(controller: _emergencyRelationController, hint: "Yakınlık Derecesi (Örn. Anne)", icon: Icons.family_restroom),

            const SizedBox(height: 10),

            // Confirmation boxes
            _buildCheckboxRow("Kişisel Verilerimin İşlenmesini Kabul Ediyorum", _dataProcessingAccepted, (v) => setState(() => _dataProcessingAccepted = v!)),
            _buildCheckboxRow("KVKK Aydınlatma Metni'ni onaylıyorum", _kvkkAccepted, (v) => setState(() => _kvkkAccepted = v!)),
            _buildCheckboxRow("Hizmet Şartları'nı onaylıyorum", _termsAccepted, (v) => setState(() => _termsAccepted = v!)),

            const SizedBox(height: 20),

            // Register button
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