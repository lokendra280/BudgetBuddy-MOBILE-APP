import 'package:flutter/material.dart';

class EmojiImage extends StatelessWidget {
  final String value;
  final double size;

  const EmojiImage({super.key, required this.value, this.size = 20});

  bool get isNetwork => value.startsWith('http');
  bool get isAsset =>
      value.startsWith('assets/') ||
      value.endsWith('.png') ||
      value.endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    // 🌐 Network Image
    if (isNetwork) {
      return Image.network(
        value,
        height: size,
        width: size,
        fit: BoxFit.contain,
      );
    }

    // 📦 Asset Image
    if (isAsset) {
      return Image.asset(value, height: size, width: size, fit: BoxFit.contain);
    }

    // 😀 Emoji (default fallback)
    return Text(value, style: TextStyle(fontSize: size));
  }
}
