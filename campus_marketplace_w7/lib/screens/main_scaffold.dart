import 'package:flutter/material.dart';
import 'home_page.dart';
import 'sell_item_page.dart';
import 'favorites_page.dart';
import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

class MainScaffold extends StatefulWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;
  const MainScaffold({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  int _favoritesRefresh = 0; // เปลี่ยนค่า = สร้างหน้า Favorites ใหม่ = โหลดข้อมูลใหม่

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        repositories: widget.itemRepositories,
        favoritesRepository: widget.favoritesRepository,
      ),
      SellItemPage(draftRepository: widget.draftRepository),
      FavoritesPage(
        key: ValueKey(_favoritesRefresh),
        repository: widget.favoritesRepository,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() {
          if (index == 2) _favoritesRefresh++; // เปิด Tab โปรดทีไร โหลดใหม่ทุกครั้ง
          _selectedIndex = index;
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: 'ลงประกาศขาย'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
        ],
      ),
    );
  }
}