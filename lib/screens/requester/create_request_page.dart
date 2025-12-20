// lib/screens/requester/create_request_page.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  // Category List
  final List<String> _categories = [
    'Enkaz Altında',
    'Su İhtiyacı',
    'Gıda İhtiyacı',
    'Isınma / Battaniye',
    'İlaç / Medikal',
    'Bebek Ürünleri',
    'Diğer'
  ];

  Future<void> _submitRequest() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir kategori seçin.")));
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen durumu kısaca açıklayın.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Takes the location currently 
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // Saves the database
      await supabase.from('requests').insert({
        'created_by': userId,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'lat': position.latitude,
        'lng': position.longitude,
        'status': 'pending', 
        'priority': 'high',  
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yardım talebi başarıyla oluşturuldu!")));
        Navigator.pop(context); 
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Yardım Talebi Oluştur"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("İhtiyaç Kategorisi", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Choosing the category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: const Text("Seçiniz", style: TextStyle(color: Colors.grey)),
                  dropdownColor: Colors.grey[800],
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: _categories.map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (newValue) => setState(() => _selectedCategory = newValue),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Durum Açıklaması", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Açıklama Kutusu
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Örn: Binanın önündeyiz, 3 kişiyiz, su yok...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // Gönder Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitRequest,
                icon: const Icon(Icons.send),
                label: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Talebi Gönder", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA94442), // Kırmızı Acil Durum Rengi
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Center(child: Text("Konumunuz otomatik olarak paylaşılacaktır.", style: TextStyle(color: Colors.grey, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}