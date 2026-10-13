import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
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
  final Set<int> _favoriteItemIds = {};
  AuthService get _authService => AuthService();

  // ── ปุ่มทดสอบ Gemini ชั่วคราว (สัปดาห์ที่ 7) ──────────────────────────
  bool _geminiLoading = false;

  Future<void> _testGemini() async {
    setState(() => _geminiLoading = true);
    try {
      final result = await GeminiService().generateText(
        'ช่วยคิดประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง โดยไม่ต้องมีชื่อร้านค้า ',
      );
      debugPrint('=== Gemini Response ===\n$result');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), duration: const Duration(seconds: 6)),
        );
      }
    } catch (e) {
      debugPrint('=== Gemini Error ===\n$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _geminiLoading = false);
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadAllItems();
    _loadFavoritesState();
  }

  void _loadAllItems() {
    setState(() {
      _itemsFuture = Future.wait(
        widget.repositories.map((repo) => repo.getItems()),
      ).then((lists) => lists.expand((items) => items).toList());
    });
  }

  Future<void> _loadFavoritesState() async {
    try {
      final favs = await widget.favoritesRepository.getAllFavorites();
      if (mounted) {
        setState(() {
          _favoriteItemIds.clear();
          _favoriteItemIds.addAll(favs.map((f) => f.itemId));
        });
      }
    } catch (_) {}
  }

  int _getIntId(dynamic id) {
    if (id is int) return id;
    if (id is String) {
      return int.tryParse(id) ?? id.hashCode.abs();
    }
    return id.hashCode.abs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          // ปุ่มทดสอบ Gemini
          _geminiLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'ทดสอบ Gemini',
                  onPressed: _testGemini,
                ),
          // ตะกร้าสินค้า
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
          // ปุ่มออกจากระบบ (Logout)
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'ออกจากระบบ',
            onPressed: () async {
              await _authService.signOut();
            },
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
            return const Center(child: Text('ไม่พบสินค้า'));
          }
          return RefreshIndicator(
            onRefresh: () async => _loadAllItems(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final intId = _getIntId(item.id);
                final isFavorite = _favoriteItemIds.contains(intId);
                final isStudentPost = item.sellerId != null;

                return ListTile(
                  leading: Image.network(
                    item.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isStudentPost
                              ? Colors.purple.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isStudentPost
                                ? Colors.purple.shade300
                                : Colors.blue.shade300,
                          ),
                        ),
                        child: Text(
                          isStudentPost ? '🎓 นศ.' : '🏪 API',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isStudentPost
                                ? Colors.purple.shade800
                                : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('${item.price} บาท'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        tooltip: isFavorite
                            ? 'อยู่ในรายการโปรดแล้ว'
                            : 'เพิ่มในรายการโปรด',
                        onPressed: () async {
                          try {
                            if (isFavorite) {
                              await widget.favoritesRepository
                                  .removeFavorite(intId);
                              if (context.mounted) {
                                setState(() {
                                  _favoriteItemIds.remove(intId);
                                });
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'ลบ "${item.title}" ออกจากรายการโปรดแล้ว'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                              }
                            } else {
                              await widget.favoritesRepository.addFavorite(
                                intId,
                                item.title,
                                item.price,
                                item.imageUrl,
                              );
                              if (context.mounted) {
                                setState(() {
                                  _favoriteItemIds.add(intId);
                                });
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'เพิ่ม "${item.title}" ในรายการโปรดแล้ว'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text('เกิดข้อผิดพลาด: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          context.read<CartModel>().add(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เพิ่ม "${item.title}" ลงตะกร้าแล้ว'),
                            ),
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
