import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PlatformScaffold extends StatelessWidget {
  const PlatformScaffold({
    super.key,
    this.title,
    this.body,
    this.actions,
    // this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.previousPageTitle,
    this.floatingActionButtonLocation,
  });

  final String? title;
  final Widget? body;
  final List<Widget>? actions;
  // final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButtonLocation;
  final String? previousPageTitle; // iOS back button label

  static bool get _isIOS => Platform.isIOS;

  @override
  Widget build(BuildContext context) =>
      _isIOS ? _buildCupertino(context) : _buildMaterial(context);

  // ── iOS ───────────────────────────────────────────────
  Widget _buildCupertino(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    navigationBar: title != null || actions != null
        ? CupertinoNavigationBar(
            middle: title != null
                ? Text(
                    title!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
                : null,
            trailing: actions != null
                ? Row(mainAxisSize: MainAxisSize.min, children: actions!)
                : null,

            previousPageTitle: previousPageTitle ?? '',
            backgroundColor:
                backgroundColor ??
                CupertinoTheme.of(context).barBackgroundColor,
          )
        : null,
    child: SafeArea(
      child: Column(
        children: [
          Expanded(child: body ?? const SizedBox()),
          if (bottomNavigationBar != null) bottomNavigationBar!,
        ],
      ),
    ),
  );

  // ── Android ───────────────────────────────────────────
  Widget _buildMaterial(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    appBar: title != null || actions != null
        ? AppBar(
            title: title != null ? Text(title!) : null,
            actions: actions,
            backgroundColor: backgroundColor,
          )
        : null,
    body: body,
    bottomNavigationBar: bottomNavigationBar,
    floatingActionButton: floatingActionButton,
  );
}
