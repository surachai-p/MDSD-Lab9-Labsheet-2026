import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'database/app_database.dart';
import 'models/cart_model.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart';
import 'repositories/favorites_repository_drift.dart';
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
      create: (context) => CartModel(),
      child: MyApp(database: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

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
        itemRepositories: [
          ItemRepositoryApi(),
          ItemRepositoryFirestore(),
        ],
        favoritesRepository: FavoritesRepositoryDrift(database),
        draftRepository: ListingDraftRepositoryDrift(database),
      ),
    );
  }
}
