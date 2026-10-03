import 'dart:convert';
import 'dart:typed_data';

import '../models/subscription.dart';

// plain json so it survives being pasted into notes or whatever
String exportBackup(List<Subscription> subs) {
  return jsonEncode({
    'app': 'subdate',
    'v': 1,
    'subs': [
      for (final s in subs)
        {
          ...s.toMap(),
          'start': s.startDate.toIso8601String().substring(0, 10),
          'ends': s.endsOn?.toIso8601String().substring(0, 10),
          'img': s.customImage == null ? null : base64Encode(s.customImage!),
        },
    ],
  });
}

List<Subscription> importBackup(String text) {
  final j = jsonDecode(text.trim());
  if (j is! Map || j['app'] != 'subdate') throw const FormatException('not a subdate backup');
  return [
    for (final m in (j['subs'] as List).cast<Map>())
      Subscription.fromMap({
        ...m,
        'start': DateTime.parse(m['start'] as String).millisecondsSinceEpoch,
        'ends': m['ends'] == null ? null : DateTime.parse(m['ends'] as String).millisecondsSinceEpoch,
        'img': m['img'] == null ? null : Uint8List.fromList(base64Decode(m['img'] as String)),
      }),
  ];
}
