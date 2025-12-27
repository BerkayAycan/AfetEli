import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  
  Future<void> _markAsCompleted(String requestId) async {
    try {
      await supabase.from('requests').update({
        'status': 'completed'
      }).eq('id', requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yardım süreci başarıyla tamamlandı!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Center(child: Text("Oturum hatası"));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Taleplerim & Durumlar"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('requests')
            .stream(primaryKey: ['id'])
            .eq('created_by', userId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allRequests = snapshot.data!;
          
          // Grouping: take only 'pending' and 'accepted' status
          final acceptedRequests = allRequests.where((r) => r['status'] == 'accepted').toList();
          final pendingRequests = allRequests.where((r) => r['status'] == 'pending').toList();

          if (acceptedRequests.isEmpty && pendingRequests.isEmpty) {
            return const Center(child: Text("Aktif bir yardım talebiniz yok.", style: TextStyle(color: Colors.grey)));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              
              // 1.Group : Volunteer On the Way
              if (acceptedRequests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.directions_run, color: Colors.blueAccent),
                      SizedBox(width: 8),
                      Text("Gönüllü Yolda", style: TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ...acceptedRequests.map((req) => _buildRequestCard(req, isAccepted: true)).toList(),
                const SizedBox(height: 20),
              ],

              // 2.Group : Waiting
              if (pendingRequests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text("Bekleniyor", style: TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ...pendingRequests.map((req) => _buildRequestCard(req, isAccepted: false)).toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req, {required bool isAccepted}) {
    Color statusColor = isAccepted ? Colors.blue : Colors.orange;
    String statusText = isAccepted ? "Gönüllü Yolda" : "Bekleniyor";

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: statusColor.withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(req['category'] ?? "Yardım", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(req['description'] ?? "Açıklama yok.", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),

            // Approved button if only status accepted
            if (isAccepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsCompleted(req['id']),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text("Yardımı Teslim Aldım", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              const Text("Henüz bir gönüllü atanmadı, lütfen bekleyiniz...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic))
          ],
        ),
      ),
    );
  }
}