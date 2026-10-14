import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../services/auth_service.dart';
import '../widgets/item_image.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  final List<ItemRepository> repositories;
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
  final Set<int> _favoriteIds = {}; // id สินค้าที่อยู่ในรายการโปรดแล้ว

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadAllItems();
    _loadFavoriteIds();
  }

  // เรียก getItems() จากทุก Repository พร้อมกัน แล้วรวมเป็นลิสต์เดียว
  // ถ้าแหล่งใดล้มเหลว ให้ข้ามแหล่งนั้น ไม่ให้ทั้งหน้าพัง
  Future<List<Item>> _loadAllItems() async {
    final results = await Future.wait(
      widget.repositories.map((r) async {
        try {
          return await r.getItems();
        } catch (e) {
          debugPrint('โหลดสินค้าจาก ${r.runtimeType} ไม่สำเร็จ: $e');
          return <Item>[];
        }
      }),
    );
    final all = results.expand((list) => list).toList();
    // ให้สินค้าที่นักศึกษาโพสต์ (มี sellerId) ขึ้นก่อนสินค้าจาก API
    all.sort((a, b) {
      final aStudent = a.sellerId != null ? 0 : 1;
      final bStudent = b.sellerId != null ? 0 : 1;
      return aStudent.compareTo(bStudent);
    });
    return all;
  }

  // ลากลงเพื่อโหลดสินค้าใหม่
  Future<void> _refresh() async {
    final future = _loadAllItems();
    setState(() => _itemsFuture = future);
    await future;
    _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    final favs = await widget.favoritesRepository.getAllFavorites();
    if (!mounted) return;
    setState(() {
      _favoriteIds
        ..clear()
        ..addAll(favs.map((f) => f.itemId));
    });
  }

  Future<void> _addToFavorites(Item item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.favoritesRepository.addFavorite(
        item.id,
        item.title,
        item.price,
        item.imageUrl,
      );
      if (!mounted) return;
      setState(() => _favoriteIds.add(item.id));
      messenger.showSnackBar(
        SnackBar(content: Text('เพิ่ม "${item.title}" ลงรายการโปรดแล้ว')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('เพิ่มรายการโปรดไม่สำเร็จ: $e')),
      );
    }
  }

  // Badge บอกแหล่งที่มา: ไม่มี sellerId = มาจาก API, มี = โพสต์โดยนักศึกษา
  Widget _sourceBadge(Item item) {
    final fromStudent = item.sellerId != null;
    return Text(
      fromStudent ? '🎓' : '🏪',
      style: const TextStyle(fontSize: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${context.watch<CartModel>().itemCount}'),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('ไม่พบสินค้า ลากลงเพื่อโหลดใหม่')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isFav = _favoriteIds.contains(item.id);
                return ListTile(
                  leading: ItemImage(url: item.imageUrl, size: 48),
                  title: Row(
                    children: [
                      _sourceBadge(item),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.title)),
                    ],
                  ),
                  subtitle: Text('${item.price} บาท'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : null,
                        ),
                        onPressed: () => _addToFavorites(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          context.read<CartModel>().add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'เพิ่ม "${item.title}" ลงตะกร้าแล้ว')),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}