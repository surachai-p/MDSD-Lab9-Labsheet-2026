import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'screens/auth_gate.dart';
import 'repositories/item_repository_dummyjson.dart';
import 'repositories/item_repository_firestore.dart'; // เพิ่มใหม่
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // สร้าง AppDatabase ครั้งเดียว แล้วส่งต่อผ่าน Constructor
  final db = AppDatabase();

  runApp(
    ChangeNotifierProvider(
      create: (context) => CartModel(),
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false,
      home: AuthGate(
        // รวมสินค้าจาก 2 แหล่ง: DummyJSON (API) และ Firestore (นักศึกษาโพสต์)
        itemRepositories: [
          ItemRepositoryDummyJson(),
          ItemRepositoryFirestore(),
        ],
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}