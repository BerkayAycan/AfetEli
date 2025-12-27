// lib/screens/admin/admin_home.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; 

// --- 1. ADMIN DASHBOARD (ANA MENÜ) ---
class AdminHomepage extends StatelessWidget {
  const AdminHomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("AFAD Yönetim Paneli"),
        backgroundColor: Colors.red[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hoş Geldiniz, Yönetici",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "İşlem yapmak istediğiniz menüyü seçiniz.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            
            // MENU GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2 sütunlu yapı
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // BUTON 1: Onay Bekleyenler
                  _buildDashboardCard(
                    context, 
                    title: "Onay Bekleyenler", 
                    icon: Icons.person_add, 
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const PendingVolunteersPage())
                      );
                    },
                  ),

                  // BUTON 2: Onaylı Gönüllüler
                  _buildDashboardCard(
                    context, 
                    title: "Onaylı Gönüllüler", 
                    icon: Icons.verified_user, 
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const ApprovedVolunteersPage())
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. SAYFA: ONAY BEKLEYENLER LİSTESİ ---
class PendingVolunteersPage extends StatefulWidget {
  const PendingVolunteersPage({super.key});

  @override
  State<PendingVolunteersPage> createState() => _PendingVolunteersPageState();
}

class _PendingVolunteersPageState extends State<PendingVolunteersPage> {
  
  // Gönüllüyü Onayla
  Future<void> _approveVolunteer(String userId) async {
    try {
      await supabase.from('users').update({
        'volunteer_status': 'approved'
      }).eq('id', userId);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gönüllü onaylandı!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  // Reddet (Statüyü boşa düşür)
  Future<void> _rejectVolunteer(String userId) async {
    try {
      await supabase.from('users').update({
        'volunteer_status': 'none' 
      }).eq('id', userId);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Başvuru reddedildi."), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Onay Bekleyenler"),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('users').stream(primaryKey: ['id']).eq('volunteer_status', 'pending'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Onay bekleyen başvuru yok.", style: TextStyle(color: Colors.grey))
            );
          }

          final rawData = snapshot.data!;

          return ListView.builder(
            itemCount: rawData.length,
            itemBuilder: (context, index) {
              final volunteer = VolunteerModel.fromJson(rawData[index]);
              
              return Card(
                color: const Color(0xFF2C2C2C),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.orange),
                  title: Text(
                    "${volunteer.firstName} ${volunteer.lastName}", 
                    style: const TextStyle(color: Colors.white)
                  ),
                  subtitle: Text(
                    volunteer.profession,
                    style: const TextStyle(color: Colors.grey)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Detay Butonu
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                        onPressed: () => _showDetailsDialog(context, volunteer),
                        tooltip: "Detayları Gör",
                      ),
                      // Onayla Butonu
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approveVolunteer(volunteer.id),
                        tooltip: "Onayla",
                      ),
                      // Reddet Butonu
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectVolunteer(volunteer.id),
                        tooltip: "Reddet",
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 3. SAYFA: ONAYLI GÖNÜLLÜLER LİSTESİ (YENİ) ---
class ApprovedVolunteersPage extends StatefulWidget {
  const ApprovedVolunteersPage({super.key});

  @override
  State<ApprovedVolunteersPage> createState() => _ApprovedVolunteersPageState();
}

class _ApprovedVolunteersPageState extends State<ApprovedVolunteersPage> {
  
  // Yetkiyi Geri Al (Revoke Access)
  Future<void> _revokeAccess(String userId) async {
    try {
      // Statüyü 'none' yaparak yetkisini alıyoruz
      await supabase.from('users').update({
        'volunteer_status': 'none' 
      }).eq('id', userId);
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gönüllünün yetkisi alındı."), backgroundColor: Colors.redAccent)
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Onaylı Gönüllüler"),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        // Sadece 'approved' olanları getir
        stream: supabase.from('users').stream(primaryKey: ['id']).eq('volunteer_status', 'approved'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Henüz onaylanmış gönüllü yok.", style: TextStyle(color: Colors.grey))
            );
          }

          final rawData = snapshot.data!;

          return ListView.builder(
            itemCount: rawData.length,
            itemBuilder: (context, index) {
              final volunteer = VolunteerModel.fromJson(rawData[index]);
              
              return Card(
                color: const Color(0xFF2C2C2C),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.green),
                  title: Text(
                    "${volunteer.firstName} ${volunteer.lastName}", 
                    style: const TextStyle(color: Colors.white)
                  ),
                  subtitle: Text(
                    "${volunteer.profession} (Aktif)",
                    style: const TextStyle(color: Colors.grey)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Detay Butonu
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blueAccent),
                        onPressed: () => _showDetailsDialog(context, volunteer),
                        tooltip: "Detayları Gör",
                      ),
                      
                      // Yetkiyi Al Butonu (Çöp Kutusu veya Yasak İkonu)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _revokeAccess(volunteer.id),
                        tooltip: "Yetkiyi Geri Al",
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- ORTAK FONKSİYONLAR (Detay Penceresi) ---
void _showDetailsDialog(BuildContext context, VolunteerModel volunteer) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Gönüllü Detayları"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Ad Soyad", "${volunteer.firstName} ${volunteer.lastName}"),
                const Divider(),
                _buildDetailRow("TC Kimlik No", volunteer.tcNo),
                const Divider(),
                _buildDetailRow("Kan Grubu", volunteer.bloodType),
                const Divider(),
                _buildDetailRow("Meslek", volunteer.profession),
                const Divider(),
                _buildDetailRow("E-Posta", volunteer.email),
                const Divider(),
                _buildDetailRow("Telefon", volunteer.phone),
                const Divider(),
                _buildDetailRow("Adres", volunteer.address),
                const Divider(),
                const Text("Acil Durum Kişisi", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 5),
                _buildDetailRow("İsim", volunteer.emergencyName),
                _buildDetailRow("Telefon", volunteer.emergencyPhone),
                _buildDetailRow("Yakınlık", volunteer.emergencyRelation),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Kapat"),
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text("$label:", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value.isEmpty ? "-" : value)),
      ],
    ),
  );
}

// --- 4. MODEL CLASS (V2) ---
class VolunteerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String profession;
  final String emergencyName;
  final String emergencyPhone;
  final String emergencyRelation;
  // V2 Fields
  final String tcNo;
  final String bloodType;
  final String address;

  VolunteerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.profession,
    required this.emergencyName,
    required this.emergencyPhone,
    required this.emergencyRelation,
    required this.tcNo,
    required this.bloodType,
    required this.address,
  });

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    return VolunteerModel(
      id: json['id'].toString(),
      firstName: json['first_name'] ?? "",
      lastName: json['last_name'] ?? "",
      email: json['email'] ?? "",
      phone: json['phone_number'] ?? "", 
      profession: json['profession'] ?? "",
      emergencyName: json['emergency_contact_name'] ?? "",
      emergencyPhone: json['emergency_contact_phone'] ?? "",
      emergencyRelation: json['emergency_contact_relation'] ?? "",
      // V2 Mappings
      tcNo: json['tc_no'] ?? "",
      bloodType: json['blood_type'] ?? "",
      address: json['address'] ?? "",
    );
  }
}