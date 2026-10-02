import 'package:flutter/material.dart';

enum Category {
  video('Video', Color(0xFFE5484D)),
  music('Music', Color(0xFF30A46C)),
  gaming('Gaming', Color(0xFF3E63DD)),
  ai('AI', Color(0xFFD97757)),
  software('Software', Color(0xFF8E4EC6)),
  cloud('Cloud', Color(0xFF0090FF)),
  reading('Reading', Color(0xFFFFB224)),
  fitness('Health', Color(0xFF12A594)),
  other('Other', Color(0xFF8B8D98));

  final String label;
  final Color color;
  const Category(this.label, this.color);

  static Category? tryParse(String? name) =>
      name == null ? null : Category.values.where((c) => c.name == name).firstOrNull;
}
