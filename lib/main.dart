import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers.dart';
import 'data/storage.dart';
import 'services/notifications.dart';
import 'theme.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = Storage();
  await storage.init();
  final notifications = Notifications();
  await notifications.init();
  runApp(ProviderScope(
    overrides: [
      storageProvider.overrideWithValue(storage),
      notificationsProvider.overrideWithValue(notifications),
    ],
    child: const SubdateApp(),
  ));
}

class SubdateApp extends StatelessWidget {
  final ThemeData? theme; // tests pass a plain one so google_fonts doesnt hit the network
  const SubdateApp({super.key, this.theme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'subdate',
      debugShowCheckedModeBanner: false,
      theme: theme ?? buildTheme(),
      home: const HomeScreen(),
    );
  }
}
