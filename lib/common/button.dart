import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PrimaryTextButton extends StatelessWidget {
  const PrimaryTextButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.color,
    this.size,
  });
  final String title;
  final Color? color;
  final double? size;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Text(
        title,
        style: TextStyle(
          color: color ?? Theme.of(context).primaryColor,
          fontSize: size ?? 14,
        ),
      ),
    );
  }
}

class CustomCupertinoIndicator extends StatelessWidget {
  final Brightness? brightness;

  const CustomCupertinoIndicator({this.brightness, super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoTheme.of(
        context,
      ).copyWith(brightness: brightness ?? Brightness.dark),
      child: const CupertinoActivityIndicator(),
    );
  }
}

// ignore: must_be_immutable
class PrimaryButton extends StatelessWidget {
  double? width;
  double? height;
  Color? color;
  final void Function()? onPressed;
  double? radius;
  Widget? icon;
  bool isDisabled;
  Color? textColor;
  Widget? widget;
  String title;
  double? textSize;

  PrimaryButton({
    super.key,
    this.radius,
    this.width,
    this.icon,
    this.isDisabled = false,
    this.textColor,
    this.widget,
    this.color,
    this.height,
    this.textSize,
    required this.onPressed,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 40.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: !isDisabled
              ? (color ?? Theme.of(context).primaryColor)
              : Colors.black45,
          elevation: 0,
          splashFactory: !isDisabled ? null : NoSplash.splashFactory,
          minimumSize: Size(width ?? double.infinity, height ?? 40.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius ?? 4)),
          ),
        ),
        child:
            widget ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: icon,
                  ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textColor ?? Colors.white,
                    fontSize: textSize ?? 20,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class PrimaryOutlinedButton extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? borderColor;
  final Function onPressed;
  final double? radius;
  final Widget? loadingWidget;
  final String title;
  final Color? titleColor;
  final Widget? icon;
  final Color? iconColor;
  final double? iconSize;

  const PrimaryOutlinedButton({
    super.key,
    this.radius,
    this.width,
    this.iconSize,
    this.borderColor,
    this.loadingWidget,
    this.icon,
    this.iconColor,
    this.height,
    this.titleColor,
    required this.onPressed,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: borderColor ?? Theme.of(context).primaryColor,
        elevation: 0,
        minimumSize: Size(width ?? double.infinity, height ?? 40.0),
        side: BorderSide(
          width: 1,
          color: borderColor ?? Theme.of(context).primaryColor,
          style: BorderStyle.solid,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius ?? 4)),
        ),
      ),
      onPressed: () {
        onPressed();
      },
      child:
          loadingWidget ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(width: iconSize ?? 15, child: icon),
                ),
              Text(
                title,
                style: TextStyle(
                  color: borderColor ?? Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
    );
  }
}

LinearGradient kLinearGradient() {
  return const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2C4373), Color(0xFF2C4373)],
  );
}
