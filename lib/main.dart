import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'data/storage.dart';
import 'theme.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = Storage();
  await storage.init();
  runApp(ProviderScope(
    overrides: [storageProvider.overrideWithValue(storage)],
    child: const SubdateApp(),
  ));
}

class SubdateApp extends StatelessWidget {
  const SubdateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'subdate',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
