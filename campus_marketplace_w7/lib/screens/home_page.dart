import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// นำเข้า Model และ Repository ที่ต้องใช้
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart'; 
import '../services/auth_service.dart'; 

class HomePage extends StatefulWidget {
  final List<ItemRepository> repositories; // รับเป็น List ของ Repositories
  final FavoritesRepository favoritesRepository;

  const HomePage({
    super.key,
    required this.repositories, 
    required this.favoritesRepository,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadAllItems();
  }

  // ฟังก์ชันดึงข้อมูลจากทุก API และ Firestore พร้อมกันแล้วเอามารวมกัน
  Future<List<Item>> _loadAllItems() async {
    final results = await Future.wait(
      widget.repositories.map((repo) => repo.getItems()),
    );
    // แปลง List ซ้อน List ให้กลายเป็น List แถวเดียว
    return results.expand((items) => items).toList();
  }

  // ฟังก์ชันจัดการรูปภาพ รองรับทั้ง Base64 และ URL ปกติ
  Widget _buildProductImage(String imageUrl) {
    // เช็คว่ารูปภาพถูกเก็บมาในรูปแบบ Base64 หรือไม่
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
    
    // ถ้าไม่ใช่ Base64 ก็โหลดจาก URL ปกติ
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
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีสินค้า'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              
              // ตรวจสอบแหล่งที่มา: API (ไอดีเป็นเลข) -> 🏪 | Firestore (ไอดีเป็นตัวอักษร) -> 🎓
              bool isFromApi = int.tryParse(item.id.toString()) != null;
              String sourceBadge = isFromApi ? '🏪' : '🎓';

              return ListTile(
                // เปลี่ยนจาก Image.network มาเรียกใช้ฟังก์ชัน _buildProductImage แทน
                leading: _buildProductImage(item.imageUrl),
                title: Row(
                  children: [
                    Text(sourceBadge),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Text('฿${item.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // ป้องกัน Error เกินขอบเขต
                  children: [
                    // ปุ่มเพิ่มลงรายการโปรด
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      color: Colors.red,
                      onPressed: () async {
                        try {
                          // เพิ่มการตรวจสอบและแปลง ID ให้เป็นตัวเลข (int) เสมอ
                          int favoriteId;
                          if (item.id is int) {
                            favoriteId = item.id as int;
                          } else {
                            favoriteId = item.id.toString().hashCode;
                          }

                          await widget.favoritesRepository.addFavorite(
                            favoriteId, // ส่งค่า ID ที่ถูกแปลงแล้วไปบันทึก
                            item.title,
                            item.price,
                            item.imageUrl,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('เพิ่มลงรายการโปรดแล้ว'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                            );
                          }
                        }
                      },
                    ),

                    // ปุ่มตะกร้า
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        Provider.of<CartModel>(
                          context,
                          listen: false,
                        ).add(item);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('เพิ่มลงตะกร้าแล้ว')),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}