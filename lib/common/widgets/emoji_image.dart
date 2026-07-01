import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class EmojiImage extends StatelessWidget {
  final String value;
  final double size;

  const EmojiImage({super.key, required this.value, this.size = 20});

  bool get isNetwork => value.startsWith('http');
  bool get isSvg => value.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(height: size, width: size);

    // 🌐 Network
    if (isNetwork) {
      if (isSvg) {
        return _CachedNetworkSvg(url: value, size: size);
      }
      return CachedNetworkImage(
        imageUrl: value,
        height: size,
        width: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      );
    }

    // 📦 Local asset
    if (isSvg) {
      return SvgPicture.asset(
        value,
        height: size,
        width: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => placeholder,
      );
    }

    return Image.asset(
      value,
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

/// Fetches SVG bytes via flutter_cache_manager (disk-cached), then renders
/// with SvgPicture.memory. Falls back silently if offline and never cached.
class _CachedNetworkSvg extends StatelessWidget {
  final String url;
  final double size;

  const _CachedNetworkSvg({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _getSvgBytes(url),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SvgPicture.memory(
            snapshot.data!,
            height: size,
            width: size,
            fit: BoxFit.contain,
          );
        }
        return SizedBox(height: size, width: size);
      },
    );
  }

  static Future<Uint8List> _getSvgBytes(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    return file.readAsBytes();
  }
}
