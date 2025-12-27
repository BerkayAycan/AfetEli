// lib/screens/auth/role_choosing_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleChoosingPage extends StatefulWidget {
  const RoleChoosingPage({super.key});

  @override
  State<RoleChoosingPage> createState() => _RoleChoosingPageState();
}

class _RoleChoosingPageState extends State<RoleChoosingPage> {
  bool _isLoading = false;
  String? _selectedRole; // 'requester' or 'volunteer'

  Future<void> _updateRoleAndNavigate() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir rol seçin.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      
      String? statusToSave;

      // LOGIC UPDATE: Check current status before overwriting it
      if (_selectedRole == 'volunteer') {
        // 1. Fetch current status from DB
        final data = await supabase
            .from('users')
            .select('volunteer_status')
            .eq('id', userId)
            .single();
        
        final currentStatus = data['volunteer_status'];

        // 2. If already 'approved', keep it 'approved'. Otherwise set to 'pending'.
        if (currentStatus == 'approved') {
          statusToSave = 'approved'; 
        } else {
          statusToSave = 'pending';
        }
      } else {
        // If requester, status is null
        statusToSave = null;
      }

      // Save the status and role to db
      await supabase.from('users').update({
        'role': _selectedRole,
        'volunteer_status': statusToSave,
      }).eq('id', userId);

      // Redirection
      if (mounted) {
        if (_selectedRole == 'requester') {
          Navigator.of(context).pushNamedAndRemoveUntil('/requester_home', (route) => false);
        } else {
          // Navigate to volunteer home (It will check status there)
          Navigator.of(context).pushNamedAndRemoveUntil('/volunteer_home', (route) => false);
        }
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ne Yapmak İstiyorsunuz?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),

            // Request a help
            _buildRoleOption(
              title: "Yardım talep etmek",
              value: "requester",
              icon: Icons.sos,
            ),
            
            const SizedBox(height: 20),

            // Being a volunteer
            _buildRoleOption(
              title: "Gönüllü olarak yardım etmek",
              value: "volunteer",
              icon: Icons.volunteer_activism,
            ),

            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRoleAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Devam Et', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text("Bu seçimi daha sonra değiştirebilirsiniz.(Eğer yalnızca sistem görevlisi tarafından onaylandıysanız gönüllü olarak giriş yapabilirsiniz!)", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({required String title, required String value, required IconData icon}) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF673AB7).withValues(alpha: 0.2) : Colors.grey[800], // Updated withValues for newer Flutter versions
          border: Border.all(
            color: isSelected ? const Color(0xFF673AB7) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF673AB7) : Colors.grey, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[400],
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF673AB7)),
          ],
        ),
      ),
    );
  }
}