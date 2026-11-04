import 'package:flutter/material.dart';
import '../repositories/item_repository_api.dart';
import 'home_page.dart';
import 'sell_item_page.dart';

import '../repositories/favorites_repository.dart';

class MainShell extends StatefulWidget {
  final FavoritesRepository? favoritesRepository;
  const MainShell({super.key, this.favoritesRepository});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      if (widget.favoritesRepository != null)
        HomePage(
          repositories: [ItemRepositoryApi()],
          favoritesRepository: widget.favoritesRepository!,
        )
      else
        const Center(child: Text('Favorites repository required')),
      const SellItemPage(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell_outlined),
            activeIcon: Icon(Icons.sell),
            label: 'ลงขายสินค้า',
          ),
        ],
      ),
    );
  }
}
