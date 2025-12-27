import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; 
import '../common/profile_page.dart';
import 'my_requests_page.dart'; 

class RequesterHomepage extends StatefulWidget {
  const RequesterHomepage({super.key});

  @override
  State<RequesterHomepage> createState() => _RequesterHomepageState();
}

class _RequesterHomepageState extends State<RequesterHomepage> {
  String _userName = "Yükleniyor...";
  String _currentAddress = "Konum aranıyor...";
  bool _isLocationLoading = true;
  int _selectedIndex = 1;

  // Notification variables
  List<Map<String, String>> _notifications = [];
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _determinePosition(); 
    _getProfile(); 
    
    // Starting to listen requests
    _listenToMyRequestUpdates();
  }

  @override
  void dispose() {
    // Stop listening when you leave the page
    if (_subscription != null) supabase.removeChannel(_subscription!);
    super.dispose();
  }

  // Liston to requests
  void _listenToMyRequestUpdates() {
    final myUserId = supabase.auth.currentUser?.id;
    if (myUserId == null) return;

    _subscription = supabase.channel('public:requests:my_updates').onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'requests',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final oldRecord = payload.oldRecord;

        // 1-) Is my request ?
        if (newRecord['created_by'] == myUserId) {
           // 2-) Is status got 'accepted' ?
           if (newRecord['status'] == 'accepted' && oldRecord['status'] != 'accepted') {
            final category = newRecord['category'] ?? "Yardım";
            final message = "$category talebinize bir Gönüllü atandı! Yardım yola çıkmak üzere.";
            final time = "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";

            if (mounted) {
              setState(() {
                _notifications.insert(0, {
                  'title': 'Gönüllü Atandı',
                  'body': message,
                  'time': time
                });
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Expanded(child: Text(message))]), 
                  backgroundColor: Colors.green
                ),
              );
            }
          }
        }
      },
    ).subscribe();
  }

  // Notification List function
  void _showNotificationList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text("Bildirimler", style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: _notifications.isEmpty
              ? const Text("Henüz bir bildirim yok.", style: TextStyle(color: Colors.grey))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.notifications_active, color: Colors.green, size: 20),
                      title: Text(notif['title']!, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: Text(notif['body']!, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Text(notif['time']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      onTap: () {
                        Navigator.pop(context);
                        _showNotificationDetail(notif['title']!, notif['body']!);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat", style: TextStyle(color: Colors.white)))
        ],
      ),
    );
  }

  void _showNotificationDetail(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E3B3B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(body, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam", style: TextStyle(color: Colors.green)))
        ],
      ),
    );
  }

  // 1-)Profile Page
  Future<void> _getProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('users')
          .select('first_name, last_name')
          .eq('id', userId)
          .single();
      
      if (mounted) {
        setState(() {
          _userName = "${data['first_name']} ${data['last_name']}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _userName = "Kullanıcı");
    }
  }

  // 2-) Finding the position 
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) setState(() { _currentAddress = "GPS Kapalı"; _isLocationLoading = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) setState(() { _currentAddress = "İzin Reddedildi"; _isLocationLoading = false; });
        return;
      }
    }

    try {
      // Takes the position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      //  WEB Control
      if (kIsWeb) {
        if(mounted) {
          setState(() {
            _currentAddress = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
            _isLocationLoading = false;
          });
        }
        return; 
      }
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if(mounted) {
          setState(() {
            _currentAddress = "${place.subAdministrativeArea}, ${place.administrativeArea}";
            _isLocationLoading = false;
          });
        }
      }
    } catch (e) {
      if(mounted) setState(() { _currentAddress = "Konum Alınamadı"; _isLocationLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    // List of pages
    List<Widget> pages = [
      const ProfilePage(),
      _buildHomeBody(userId),
      const MyRequestsPage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[600],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, 
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hesabım'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.history_edu), label: 'Taleplerim'),
        ],
      ),
    );
  }

  Widget _buildHomeBody(String? userId) {
    return Column(
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(20)),
                child: const Text("Rol: Afetzede", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, '/role_choose'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(20)),
                  child: const Row(children: [Icon(Icons.swap_horiz, size: 18), SizedBox(width: 4), Text("Rolü değiştir")]),
                ),
              ),
              
              // Notification Icon
              InkWell(
                onTap: _showNotificationList,
                child: CircleAvatar(
                  backgroundColor: _notifications.isNotEmpty ? Colors.redAccent : Colors.grey[600],
                  child: Icon(Icons.notifications_active, color: Colors.black),
                ),
              )
            ],
          ),
        ),

        // Welcome Message 
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(30)),
          child: Text(
            "Hoş geldiniz, $_userName!",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(height: 10),

        // Location Info
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(40)),
          child: Column(
            children: [
               _isLocationLoading
                  ? const Text("Konum Bulunuyor...", style: TextStyle(color: Colors.white))
                  : Text("Konum : $_currentAddress (Otomatik)", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // List Space
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3E3B3B),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.history, color: Colors.white), SizedBox(width: 8), Text("Geçmiş (Tamamlanan) Talepler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
                  ),
                  const SizedBox(height: 15),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                         Navigator.pushNamed(context, '/create_request');
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("Yeni Yardım Talebi Oluştur", style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Filtered list (Just Completed)
                  Expanded(
                    child: userId == null 
                    ? const Center(child: Text("Oturum Hatası")) 
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: supabase
                            .from('requests')
                            .stream(primaryKey: ['id'])
                            .eq('created_by', userId) 
                            .order('created_at', ascending: false), 
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text("Hata: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                          }
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final allRequests = snapshot.data!;
                          final completedRequests = allRequests.where((r) => r['status'] == 'completed').toList();

                          if (completedRequests.isEmpty) {
                            return const Center(child: Text("Henüz tamamlanmış bir talebiniz yok.", style: TextStyle(color: Colors.grey)));
                          }

                          return ListView.builder(
                            itemCount: completedRequests.length,
                            itemBuilder: (context, index) {
                              final req = completedRequests[index];
                              return _buildRequestCard(
                                req['category'] ?? 'Bilinmiyor',
                                req['status'] ?? 'completed',
                                req['created_at'] ?? '',
                              );
                            },
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Card Design
  Widget _buildRequestCard(String title, String status, String timeString) {
    String displayTime = timeString;
    try {
      final DateTime dt = DateTime.parse(timeString).toLocal();
      displayTime = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}";
    } catch (e) { }

    const statusText = "Tamamlandı";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.4), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4))
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.check, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.white70),
                    SizedBox(width: 4),
                    Text("Durum : Tamamlandı", style: TextStyle(fontSize: 13, color: Colors.white)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(displayTime, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}