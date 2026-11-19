import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart_model.dart';
import '../models/item.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/item_repository.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import 'checkout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.repositories,
    required this.favoritesRepository,
  });

  final List<ItemRepository> repositories;
  final FavoritesRepository favoritesRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _itemsFuture = _fetchCombinedItems();
    });
  }

  Future<List<Item>> _fetchCombinedItems() async {
    final results = await Future.wait(
      widget.repositories.map((repo) async {
        try {
          return await repo.getItems();
        } catch (e) {
          debugPrint('Error loading from repository $repo: $e');
          return <Item>[];
        }
      }),
    );
    return results.expand((items) => items).toList();
  }

  Future<void> _testGemini() async {
    try {
      final message = await GeminiService().generateText(
        'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
      );
      debugPrint('Gemini: $message');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gemini error: $error')));
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            tooltip: 'ทดสอบ Gemini แบบข้อความ',
            icon: const Icon(Icons.auto_awesome),
            onPressed: _testGemini,
          ),
          IconButton(
            icon: Badge(
              label: Text('${cart.itemCount}'),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CheckoutPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: _handleSignOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadItems(),
        child: FutureBuilder<List<Item>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'เกิดข้อผิดพลาด: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return const Center(
                child: Text('ไม่พบรายการสินค้า'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isFirestore = item.sellerId != null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: SizedBox(
                        width: 56,
                        height: 56,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isFirestore
                                      ? Colors.blue[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isFirestore ? '🎓 โพสต์โดยนักศึกษา' : '🏪 ร้านค้า API',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFirestore
                                        ? Colors.blue[900]
                                        : Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '฿${item.price.toStringAsFixed(2)} • ${item.category}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_border),
                            tooltip: 'เพิ่มในรายการโปรด',
                            onPressed: () async {
                              try {
                                final favId = item.id is int
                                    ? item.id as int
                                    : (int.tryParse(item.id.toString()) ??
                                        item.id.hashCode.abs());
                                await widget.favoritesRepository.addFavorite(
                                  favId,
                                  item.title,
                                  item.price,
                                  item.imageUrl,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'เพิ่ม "${item.title}" ในรายการโปรดแล้ว'),
                                    ),
                                  );
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'ไม่สามารถเพิ่มในรายการโปรดได้: $error'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          FilledButton(
                            onPressed: () {
                              context.read<CartModel>().add(item);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('เพิ่ม ${item.title} ลงตะกร้าแล้ว'),
                                ),
                              );
                            },
                            child: const Text('เพิ่ม'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
