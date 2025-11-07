// call early in each test (or in a setUpAll that launches the screen)

import 'package:flutter/cupertino.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

class PermissionsHelper {
  Future<void> grantAllVisiblePermissions(PatrolIntegrationTester $) async {
    // Try up to 3 times to handle multiple permission dialogs
    for (var i = 0; i < 3; i++) {
      final visible = await $.native.isPermissionDialogVisible(
        timeout: const Duration(seconds: 5),
      );

      if (!visible) {
        debugPrint(
            'PermissionsHelper: No permission dialog visible (attempt ${i + 1}/3)');
        break;
      }

      debugPrint(
          'PermissionsHelper: Permission dialog detected (attempt ${i + 1}/3)');

      // Try multiple strategi
      // es to grant the permission
      bool granted = false;

      // Strategy 1: Use Patrol's built-in helper for "When in use"
      try {
        debugPrint('PermissionsHelper: Trying grantPermissionWhenInUse()');
        await $.native.grantPermissionWhenInUse();
        granted = true;
        debugPrint(
            'PermissionsHelper: Successfully granted via grantPermissionWhenInUse()');
      } catch (e) {
        debugPrint('PermissionsHelper: grantPermissionWhenInUse() failed: $e');
      }

      // Strategy 2: Fall back to "Only this time" on Android 12+
      if (!granted) {
        try {
          debugPrint('PermissionsHelper: Trying grantPermissionOnlyThisTime()');
          await $.native.grantPermissionOnlyThisTime();
          granted = true;
          debugPrint(
              'PermissionsHelper: Successfully granted via grantPermissionOnlyThisTime()');
        } catch (e) {
          debugPrint(
              'PermissionsHelper: grantPermissionOnlyThisTime() failed: $e');
        }
      }

      if (!granted) {
        debugPrint(
            'PermissionsHelper: WARNING - Could not grant permission, may have been pre-granted or dialog closed');
      }

      // Wait a bit for the dialog to dismiss and app to settle
      await $.pump(const Duration(milliseconds: 300));
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));
    }
  }
}
