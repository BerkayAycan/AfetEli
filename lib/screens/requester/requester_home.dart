import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; 

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

  @override
  void initState() {
    super.initState();
    _determinePosition(); 
    _getProfile();        
  }

  // --- 1-)Profile Page ---
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

  // --- 2--Finding the position ---
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
      
      // --- WEB Control (Adress transition doesnt work on Web) ---
      if (kIsWeb) {
        if(mounted) {
          setState(() {
            // Just coordination  seems ob web cause of proventing to error
            _currentAddress = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
            _isLocationLoading = false;
          });
        }
        return; 
      }
      // If mobile version is active show the location name
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

    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: SafeArea(
        child: Column(
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
                  CircleAvatar(backgroundColor: Colors.grey[600], child: const Icon(Icons.notifications_none, color: Colors.black))
                ],
              ),
            ),

            // Welcome message
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

            // Location info
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

            // List space
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
                        children: [Icon(Icons.mail_outline, color: Colors.white), SizedBox(width: 8), Text("Yardım Taleplerim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
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
                      const Text("Geçmiş Yardım Taleplerim", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // live data list
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
                              
                              final requests = snapshot.data!;

                              if (requests.isEmpty) {
                                return const Center(child: Text("Henüz bir yardım talebiniz yok.", style: TextStyle(color: Colors.grey)));
                              }

                              return ListView.builder(
                                itemCount: requests.length,
                                itemBuilder: (context, index) {
                                  final req = requests[index];
                                  return _buildRequestCard(
                                    req['category'] ?? 'Bilinmiyor',
                                    req['status'] ?? 'pending',
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
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[600],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hesabım'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String title, String status, String timeString) {
    String displayTime = timeString;
    try {
      final DateTime dt = DateTime.parse(timeString).toLocal();
      displayTime = "${dt.hour}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}";
    } catch (e) { }

    String statusText = "Bekleniyor";
    if (status == 'accepted') statusText = "Gönüllü Atandı";
    if (status == 'completed') statusText = "Tamamlandı";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFA94442), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            child: const Text("SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text("Durum : $statusText", style: const TextStyle(fontSize: 13, color: Colors.white)),
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