// lib/screens/admin/admin_home.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; 

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  
  // Approvement of been volunteer request
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
      if(mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Detail window
  void _showDetailsDialog(VolunteerModel volunteer) {
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
                  _buildDetailRow("Meslek", volunteer.profession),
                  const Divider(),
                  _buildDetailRow("E-Posta", volunteer.email),
                  const Divider(),
                  _buildDetailRow("Telefon", volunteer.phone),
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

  // Helper widget
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Onay Bekleyen Gönüllü Başvuruları", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              // If someone press button that 'be a voluteer' on RoleChoosingPage this trigger will be triggered.
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
                        leading: const Icon(Icons.person_outline, color: Colors.orange),
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
                            // Detail button
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 8)
                              ),
                              icon: const Icon(Icons.visibility, size: 16),
                              label: const Text("Detay", style: TextStyle(fontSize: 12)),
                              onPressed: () => _showDetailsDialog(volunteer),
                            ),
                            const SizedBox(width: 8),
                            // Approve button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 8)
                              ),
                              onPressed: () => _approveVolunteer(volunteer.id),
                              child: const Text("Onayla", style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Model class
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
    );
  }
}