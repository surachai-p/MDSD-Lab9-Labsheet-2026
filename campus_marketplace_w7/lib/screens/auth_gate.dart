import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../repositories/favorites_repository.dart';
import '../repositories/item_repository.dart';
import '../repositories/listing_draft_repository.dart';
import '../screens/login_page.dart';
import '../screens/main_scaffold.dart';

class AuthGate extends StatelessWidget {
  final List<ItemRepository> itemRepositories;
  final FavoritesRepository favoritesRepository;
  final ListingDraftRepository draftRepository;

  const AuthGate({
    super.key,
    required this.itemRepositories,
    required this.favoritesRepository,
    required this.draftRepository,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // สถานะ 1: รอผลรอบแรก
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // สถานะ 2: ยังไม่ล็อกอิน
        if (snapshot.data == null) {
          return const LoginPage();
        }

        // สถานะ 3: ล็อกอินแล้ว
        return MainScaffold(
          itemRepositories: itemRepositories, // ชั่วคราว จะแก้ในขั้น 5.3
          favoritesRepository: favoritesRepository,
          draftRepository: draftRepository,
        );
      },
    );
  }
}