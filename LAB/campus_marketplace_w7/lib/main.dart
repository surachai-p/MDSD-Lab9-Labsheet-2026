import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  // จำเป็นสำหรับการเรียก Native Code ก่อน runApp
  WidgetsFlutterBinding.ensureInitialized();

  // โหลดการตั้งค่า Firebase จากไฟล์ที่ FlutterFire สร้างให้
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate(
        itemRepositories: [ItemRepositoryApi(), ItemRepositoryFirestore()],
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}
