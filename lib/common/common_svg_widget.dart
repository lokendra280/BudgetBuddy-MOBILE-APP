import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommonSvgWidget extends StatelessWidget {
  final String svgName;
  final double? height;
  final double? width;
  final Color? color;
  const CommonSvgWidget({
    super.key,
    required this.svgName,
    this.height = 16,
    this.width = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Container(
      padding: EdgeInsets.all(isIOS ? 2 : 1),
      child: SvgPicture.asset(
        svgName,
        height: height ?? (isIOS ? 22 : 20),
        width: width ?? (isIOS ? 22 : 20),
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      ),
    );
  }
}
