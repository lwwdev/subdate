import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';

class Brand {
  final String key;
  final String name;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final double? price; // rough default, CAD-ish
  final String currency;

  const Brand(this.key, this.name, this.icon, this.bg,
      {this.fg = Colors.white, this.price, this.currency = 'CAD'});
}

// simple_icons doesnt have openai/disney/prime anymore so those get a generic glyph
const brands = <Brand>[
  Brand('spotify', 'Spotify', SimpleIcons.spotify, Colors.black, fg: SimpleIconColors.spotify, price: 12.99),
  Brand('playstation', 'PlayStation Plus', SimpleIcons.playstation, Colors.white, fg: Colors.black, price: 11.99),
  Brand('chatgpt', 'ChatGPT', Icons.blur_on_rounded, Color(0xFFF4F4F4), fg: Colors.black, price: 20, currency: 'USD'),
  Brand('claude', 'Claude', SimpleIcons.claude, Color(0xFFD97757), price: 20, currency: 'USD'),
  Brand('netflix', 'Netflix', SimpleIcons.netflix, Colors.black, fg: SimpleIconColors.netflix, price: 18.99),
  Brand('youtube', 'YouTube Premium', SimpleIcons.youtube, Colors.white, fg: SimpleIconColors.youtube, price: 13.99),
  Brand('youtubemusic', 'YouTube Music', SimpleIcons.youtubemusic, SimpleIconColors.youtubemusic, price: 10.99),
  Brand('applemusic', 'Apple Music', SimpleIcons.applemusic, SimpleIconColors.applemusic, price: 10.99),
  Brand('appletv', 'Apple TV+', SimpleIcons.appletv, Colors.black, price: 12.99),
  Brand('icloud', 'iCloud+', SimpleIcons.icloud, SimpleIconColors.icloud, price: 1.29),
  Brand('disney', 'Disney+', Icons.castle_rounded, Color(0xFF0E1C5A), price: 11.99),
  Brand('prime', 'Prime Video', Icons.play_arrow_rounded, Color(0xFF1A98FF), price: 9.99),
  Brand('max', 'Max', SimpleIcons.max, Color(0xFF002BE7), price: 16.99),
  Brand('crunchyroll', 'Crunchyroll', SimpleIcons.crunchyroll, SimpleIconColors.crunchyroll, price: 9.99),
  Brand('paramountplus', 'Paramount+', SimpleIcons.paramountplus, SimpleIconColors.paramountplus, price: 8.99),
  Brand('xbox', 'Xbox Game Pass', Icons.sports_esports_rounded, Color(0xFF107C10), price: 19.99),
  Brand('steam', 'Steam', SimpleIcons.steam, Color(0xFF171A21)),
  Brand('twitch', 'Twitch', SimpleIcons.twitch, SimpleIconColors.twitch, price: 5.99),
  Brand('discord', 'Discord Nitro', SimpleIcons.discord, SimpleIconColors.discord, price: 13.99),
  Brand('github', 'GitHub', SimpleIcons.github, Color(0xFF24292F), price: 4, currency: 'USD'),
  Brand('cursor', 'Cursor', SimpleIcons.cursor, Colors.black, price: 20, currency: 'USD'),
  Brand('perplexity', 'Perplexity', SimpleIcons.perplexity, Color(0xFF1F1F1F), fg: SimpleIconColors.perplexity, price: 20, currency: 'USD'),
  Brand('notion', 'Notion', SimpleIcons.notion, Colors.white, fg: Colors.black, price: 10, currency: 'USD'),
  Brand('figma', 'Figma', SimpleIcons.figma, Colors.black, price: 16, currency: 'USD'),
  Brand('dropbox', 'Dropbox', SimpleIcons.dropbox, SimpleIconColors.dropbox, price: 14.99),
  Brand('googledrive', 'Google One', SimpleIcons.googledrive, Colors.white, fg: Color(0xFF4285F4), price: 2.79),
  Brand('duolingo', 'Duolingo', SimpleIcons.duolingo, SimpleIconColors.duolingo, price: 12.99),
  Brand('audible', 'Audible', SimpleIcons.audible, SimpleIconColors.audible, price: 14.95),
  Brand('tidal', 'Tidal', SimpleIcons.tidal, Colors.black, price: 10.99),
  Brand('deezer', 'Deezer', SimpleIcons.deezer, Color(0xFFA238FF), price: 11.99),
  Brand('soundcloud', 'SoundCloud', SimpleIcons.soundcloud, SimpleIconColors.soundcloud, price: 10.99),
  Brand('patreon', 'Patreon', SimpleIcons.patreon, Colors.black),
  Brand('substack', 'Substack', SimpleIcons.substack, SimpleIconColors.substack),
  Brand('medium', 'Medium', SimpleIcons.medium, Colors.black, price: 5, currency: 'USD'),
  Brand('x', 'X Premium', SimpleIcons.x, Colors.black, price: 8, currency: 'USD'),
  Brand('grammarly', 'Grammarly', SimpleIcons.grammarly, SimpleIconColors.grammarly, price: 12, currency: 'USD'),
  Brand('nordvpn', 'NordVPN', SimpleIcons.nordvpn, SimpleIconColors.nordvpn),
  Brand('proton', 'Proton', SimpleIcons.proton, SimpleIconColors.proton),
];

final _byKey = {for (final b in brands) b.key: b};

Brand? brandFor(String? key) => key == null ? null : _byKey[key];
