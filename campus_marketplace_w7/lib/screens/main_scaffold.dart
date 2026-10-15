import 'package:flutter/material.dart';

import '../repositories/item_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/listing_draft_repository.dart';

import 'home_page.dart';
import 'my_drafts_page.dart'; // เปลี่ยนมา import หน้ารายการร่างแทน
import 'favorites_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        repositories: widget.itemRepositories,
        favoritesRepository: widget.favoritesRepository,
      ),
      // แท็บที่ 2 เรียก MyDraftsPage (หน้ารายการร่าง) ขึ้นมาแสดง
      MyDraftsPage(draftRepository: widget.draftRepository),
      FavoritesPage(repository: widget.favoritesRepository),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'หน้าแรก'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'รายการร่าง'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'รายการโปรด'),
        ],
      ),
    );
  }
}