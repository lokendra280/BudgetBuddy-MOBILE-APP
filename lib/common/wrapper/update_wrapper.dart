import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateWrapper extends StatefulWidget {
  final Widget child;

  const UpdateWrapper({super.key, required this.child});

  @override
  State<UpdateWrapper> createState() => _UpdateWrapperState();
}

class _UpdateWrapperState extends State<UpdateWrapper> {
  @override
  void initState() {
    super.initState();
    _checkInApp();
  }

  void _checkInApp() async {
    if (kDebugMode) {
      debugPrint('⚠️ Skipping in-app update (debug mode)');
      return;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
        // 🔹 Only fallback to immediate if required
        else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } catch (e) {
      debugPrint('In-app update error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
