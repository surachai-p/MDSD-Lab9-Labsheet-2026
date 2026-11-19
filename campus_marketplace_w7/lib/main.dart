import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/app_database.dart';
import 'firebase_options.dart';
import 'models/cart_model.dart';
import 'repositories/favorites_repository.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/item_repository.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart';
import 'repositories/listing_draft_repository.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = AppDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.db,
    this.itemRepositories,
    this.favoritesRepository,
    this.draftRepository,
  });

  final AppDatabase? db;
  final List<ItemRepository>? itemRepositories;
  final FavoritesRepository? favoritesRepository;
  final ListingDraftRepository? draftRepository;

  @override
  Widget build(BuildContext context) {
    final database = db ?? AppDatabase();
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: AuthGate(
        itemRepositories: itemRepositories ??
            [
              ItemRepositoryApi(),
              ItemRepositoryFirestore(),
            ],
        favoritesRepository:
            favoritesRepository ?? FavoritesRepositoryDrift(database),
        draftRepository:
            draftRepository ?? ListingDraftRepositoryDrift(database),
      ),
    );
  }
}
