import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;

  const FavoritesPage({super.key, required this.repository});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = widget.repository.getAllFavorites();
    });
  }

  // ฟังก์ชันจัดการรูปภาพ รองรับทั้ง Base64 และ URL ปกติ
  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final String base64String = imageUrl.split(',').last;
        final Uint8List decodedBytes = base64Decode(base64String);
        return Image.memory(
          decodedBytes,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
      }
    } 
    
    return Image.network(
      imageUrl,
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_not_supported, size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรด')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ'));
          }

          final favorites = snapshot.data!;
          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return ListTile(
                // เปลี่ยนมาใช้ฟังก์ชัน _buildProductImage แทน Image.network
                leading: _buildProductImage(item.imageUrl),
                title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('฿${item.price.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await widget.repository.removeFavorite(item.itemId);
                    _loadFavorites(); // โหลดข้อมูลใหม่หลังลบ
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