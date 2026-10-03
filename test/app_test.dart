import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subdate/data/providers.dart';
import 'package:subdate/data/storage.dart';
import 'package:subdate/main.dart';
import 'package:subdate/services/notifications.dart';
import 'package:subdate/theme.dart';

void main() {
  late Directory dir;
  late Storage storage;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('subdate');
    storage = Storage();
    await storage.init(path: dir.path);
  });

  tearDown(() => dir.delete(recursive: true));

  Widget app() => ProviderScope(
        overrides: [
          storageProvider.overrideWithValue(storage),
          notificationsProvider.overrideWithValue(Notifications()),
        ],
        child: SubdateApp(theme: buildTheme(googleFonts: false)),
      );

  testWidgets('empty state -> sample data -> cards + calendar', (t) async {
    await t.binding.setSurfaceSize(const Size(400, 2000));
    await t.runAsync(() async {
      await t.pumpWidget(app());
      await t.pump();
      expect(find.text('no subs yet'), findsOneWidget);

      await t.tap(find.text('Load sample data'));
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();

    expect(find.text('Coming up'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Spending'), findsOneWidget);
    expect(find.text('today'), findsOneWidget); // spotify renews today in the sample
    expect(storage.loadSubs().length, 6);
  });
}
