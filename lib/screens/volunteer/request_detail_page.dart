import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart';
import '../../main.dart'; // To access the global 'supabase' client

class RequestDetailPage extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const RequestDetailPage({super.key, required this.requestData});

  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  // --- Variables ---
  bool _isLoading = false;
  bool _isFetchingUser = true;
  Map<String, dynamic>? _requesterInfo; // Stores detailed user info (Address, Blood Type, etc.)

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _fetchRequesterDetails(); // Fetch user details when page loads
  }

  // --- Methods ---

  // Fetch detailed info of the person who created the request from 'users' table
  Future<void> _fetchRequesterDetails() async {
    try {
      final userId = widget.requestData['created_by'];
      
      // If user_id exists, fetch data from 'users' table
      if (userId != null) {
        final data = await supabase
            .from('users')
            .select()
            .eq('id', userId)
            .single();
            
        if (mounted) {
          setState(() {
            _requesterInfo = data;
            _isFetchingUser = false;
          });
        }
      } else {
        if (mounted) setState(() => _isFetchingUser = false);
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
      if (mounted) setState(() => _isFetchingUser = false);
    }
  }

  // Function that opens map
  void _showMapModal(BuildContext context, double lat, double lng) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, 
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 10),
              
              const Text("Konum Bilgisi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Map
              Expanded(
                child: ClipRRect( // For radius
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng), 
                      initialZoom: 15.0, // Initial zoom level
                    ),
                    children: [
                      // 1-) Map layer (OpenStreetMap)
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      // 2-) Marker layer
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 80,
                            height: 80,
                            child: const Icon(
                              Icons.location_on, 
                              color: Colors.red, 
                              size: 50,
                              shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Close button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                    child: const Text("Kapat", style: TextStyle(color: Colors.white)),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _acceptRequest() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('requests').update({
        'status': 'accepted',
        'volunteer_id': userId,
      }).eq('id', widget.requestData['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yardım talebini kabul ettiniz!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper widget to build info rows cleanly
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 15),
                children: [
                  TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.requestData;
    // Takes the coordinats securely
    final double lat = req['lat'] ?? 0.0;
    final double lng = req['lng'] ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: const Text("Talep Detayı"), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFA94442),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                req['category'] ?? 'Bilinmiyor',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            const Text("Açıklama:", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 5),
            Text(req['description'] ?? 'Açıklama yok', style: const TextStyle(color: Colors.white, fontSize: 18)),

            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),

            // --- NEW SECTION: Requester Details (Fetched from 'users' table) ---
            const Text("Talep Eden Kişi Bilgileri", style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Show loading or data
            _isFetchingUser 
              ? const Center(child: CircularProgressIndicator()) 
              : _requesterInfo == null 
                  ? const Text("Kullanıcı bilgisi alınamadı.", style: TextStyle(color: Colors.grey))
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.person, "Ad Soyad", "${_requesterInfo!['first_name']} ${_requesterInfo!['last_name']}"),
                          _buildInfoRow(Icons.phone, "Telefon", "${_requesterInfo!['phone_number']}"),
                          _buildInfoRow(Icons.bloodtype, "Kan Grubu", "${_requesterInfo!['blood_type'] ?? 'Belirtilmemiş'}"),
                          // Address might be long, so it wraps automatically
                          _buildInfoRow(Icons.location_city, "Adres", "${_requesterInfo!['address'] ?? 'Adres girilmemiş'}"),
                          // Uncomment below if you want to show TC No
                          // _buildInfoRow(Icons.badge, "TC No", "${_requesterInfo!['tc_no'] ?? '-'}"),
                        ],
                      ),
                    ),

            const SizedBox(height: 20),

            // See location button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (lat != 0.0 && lng != 0.0) {
                    _showMapModal(context, lat, lng);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu talebin konum bilgisi eksik.")));
                  }
                },
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text("Konumu Haritada Gör", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2), 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const Spacer(),

            // Accept button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _acceptRequest,
                icon: const Icon(Icons.check_circle),
                label: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Yardımı Kabul Et", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}