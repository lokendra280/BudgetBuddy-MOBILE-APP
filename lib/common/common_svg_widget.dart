import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonSvgWidget extends StatelessWidget {
  final String svgName;
  final double? height;
  final double? width;
  final Color? color;
  final BoxFit fit;

  const CommonSvgWidget({
    super.key,
    required this.svgName,
    this.height = 16,
    this.width = 16,
    this.color,
    this.fit = BoxFit.contain,
  });

  bool get _isSvg => svgName.toLowerCase().trim().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    final resolvedHeight = height ?? (isIOS ? 22 : 20);
    final resolvedWidth = width ?? (isIOS ? 22 : 20);

    return Container(
      padding: EdgeInsets.all(isIOS ? 2 : 1),
      child: _isSvg
          ? SvgPicture.asset(
              svgName,
              height: resolvedHeight,
              width: resolvedWidth,
              fit: fit,
              colorFilter: color != null
                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                  : null,
            )
          : Image.asset(
              svgName,
              height: resolvedHeight,
              width: resolvedWidth,
              fit: fit,
              color: color,
              colorBlendMode: color != null ? BlendMode.srcIn : null,
            ),
    );
  }
}
