import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateWrapper extends StatefulWidget {
  final Widget child;

  /// Two-letter App Store country code where the app is listed
  /// (e.g. 'np', 'in', 'us'). Apple's lookup returns nothing if this
  /// doesn't match a store the app is available in.
  final String appStoreCountry;

  const UpdateWrapper({
    super.key,
    required this.child,
    this.appStoreCountry = 'np',
  });

  @override
  State<UpdateWrapper> createState() => _UpdateWrapperState();
}

class _UpdateWrapperState extends State<UpdateWrapper> {
  @override
  void initState() {
    super.initState();
    // Wait for the first frame so a dialog can be shown safely.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (kDebugMode) {
      debugPrint('⚠️ Skipping update check (debug mode)');
      return;
    }
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        await _checkAndroid();
      } else if (Platform.isIOS) {
        await _checkIOS();
      }
    } catch (e) {
      debugPrint('Update check error: $e');
    }
  }

  // ---------------- Android: Google Play in-app update ----------------

  Future<void> _checkAndroid() async {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) return;

    if (info.flexibleUpdateAllowed) {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } else if (info.immediateUpdateAllowed) {
      await InAppUpdate.performImmediateUpdate();
    }
  }

  // ---------------- iOS: App Store version check ----------------

  Future<void> _checkIOS() async {
    final packageInfo = await PackageInfo.fromPlatform();

    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': packageInfo.packageName,
      'country': widget.appStoreCountry,
      // Stops Apple's servers returning a cached, outdated version.
      't': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List<dynamic>?) ?? [];
    if (results.isEmpty) return; // Not found in this country's store.

    final app = results.first as Map<String, dynamic>;
    final storeVersion = app['version'] as String?;
    final storeUrl = app['trackViewUrl'] as String?;
    if (storeVersion == null || storeUrl == null) return;

    if (!_isNewer(storeVersion, packageInfo.version)) return;
    if (!mounted) return;

    _showIOSUpdateDialog(storeVersion, storeUrl);
  }

  /// True if [store] is a higher version than [current] (e.g. 1.2.10 > 1.2.9).
  bool _isNewer(String store, String current) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    final a = parse(store);
    final b = parse(current);
    final length = a.length > b.length ? a.length : b.length;

    for (var i = 0; i < length; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  void _showIOSUpdateDialog(String version, String storeUrl) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Update available'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Version $version is now on the App Store with the latest '
            'fixes and improvements.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await launchUrl(
                Uri.parse(storeUrl),
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
