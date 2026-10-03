import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: SubdateApp()));
}

class SubdateApp extends StatelessWidget {
  const SubdateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'subdate',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Scaffold(body: Center(child: Text('soon'))),
    );
  }
}
