import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import 'request_detail_page.dart'; 

class ActiveTasksPage extends StatelessWidget {
  const ActiveTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return const Center(child: Text("Oturum hatası"));

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Devam Eden Görevlerim"),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('requests')
            .stream(primaryKey: ['id'])
            .eq('volunteer_id', userId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allTasks = snapshot.data!;

          final tasks = allTasks.where((task) => task['status'] == 'accepted').toList();

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  const Text("Şu an üzerinizde aktif bir görev yok.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                color: const Color(0xFF2C2C2C),
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(task['category'] ?? "Yardım", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      const Text("Durum: Devam Ediyor (Afetzede onayı bekleniyor)", style: TextStyle(color: Colors.blueAccent)),
                      const SizedBox(height: 5),
                      Text(task['description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RequestDetailPage(requestData: task)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}