import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart'; 
import 'request_detail_page.dart';
import '../common/profile_page.dart';
import '../common/settings_page.dart';

class VolunteerHomepage extends StatefulWidget {
  const VolunteerHomepage({super.key});

  @override
  State<VolunteerHomepage> createState() => _VolunteerHomepageState();
}

class _VolunteerHomepageState extends State<VolunteerHomepage> {
  String _userName = "Yükleniyor...";
  Position? _currentPosition;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _getProfile();
  }

  // Get the Profile name
  Future<void> _getProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('users').select('first_name, last_name').eq('id', userId).single();
      if (mounted) setState(() => _userName = "${data['first_name']} ${data['last_name']}");
    } catch (e) { /* S */ }
  }

  // Find location
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) setState(() => _currentPosition = position);
  }

  @override
  Widget build(BuildContext context) {
    // Sayfaların Listesi
    List<Widget> pages = [
      const ProfilePage(),       
      _buildVolunteerBody(),     
      const SettingsPage(),      
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
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hesabım'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Anasayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }

  Widget _buildVolunteerCard(Map<String, dynamic> req, String distance) {
    // Time format
    String timeAgo = "Az önce";
    try {
      final created = DateTime.parse(req['created_at']).toLocal();
      final diff = DateTime.now().difference(created);
      if (diff.inMinutes < 60) timeAgo = "${diff.inMinutes} dk önce";
      else if (diff.inHours < 24) timeAgo = "${diff.inHours} saat önce";
      else timeAgo = "${diff.inDays} gün önce";
    } catch (e) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFA94442), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: const Text("SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${req['category']} - $distance", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        const Text("Konum bilgisi alındı", style: TextStyle(fontSize: 13, color: Colors.white)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(timeAgo, style: const TextStyle(fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 10),
          
          // Show Details button
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestDetailPage(requestData: req)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.play_arrow, size: 16),
                   SizedBox(width: 4),
                   Text("Detayları Gör"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildHeaderChip(String? text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(20)),
      child: Row(children: [if (icon != null) Icon(icon, size: 18), if (icon != null) const SizedBox(width: 4), Text(text ?? "", style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }
  Widget _buildVolunteerBody() {
    return Column(
      children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildHeaderChip("Rol: Gönüllü"),
               InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, '/role_choose'),
                child: _buildHeaderChip("Rolü değiştir", icon: Icons.swap_horiz),
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
          child: Text("Hoş geldiniz, $_userName!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 10),

        // LLocation and search button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF424242), borderRadius: BorderRadius.circular(40)),
          child: Column(
            children: [
              Text("Konum : ${_currentPosition != null ? 'Konum Alındı' : 'Konum Aranıyor...'}", style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "Yardım Çağrısı Ara",
                  filled: true,
                  fillColor: Colors.grey[600],
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
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
                    children: [Icon(Icons.mail_outline, color: Colors.white), SizedBox(width: 8), Text("Yardım Çağrıları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))],
                  ),
                  const SizedBox(height: 15),

                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: supabase.from('requests').stream(primaryKey: ['id']).eq('status', 'pending').order('created_at', ascending: false),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final requests = snapshot.data!;
                        if (requests.isEmpty) return const Center(child: Text("Bekleyen yardım çağrısı yok.", style: TextStyle(color: Colors.grey)));

                        return ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            String distanceText = "...";
                            if (_currentPosition != null && req['lat'] != null && req['lng'] != null) {
                              double distanceInMeters = Geolocator.distanceBetween(
                                _currentPosition!.latitude, _currentPosition!.longitude,
                                req['lat'], req['lng']
                              );
                              distanceText = distanceInMeters > 1000 
                                  ? "${(distanceInMeters / 1000).toStringAsFixed(1)} km" 
                                  : "${distanceInMeters.toStringAsFixed(0)} m";
                            }
                            return _buildVolunteerCard(req, distanceText);
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
}