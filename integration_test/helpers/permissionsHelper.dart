// call early in each test (or in a setUpAll that launches the screen)

import 'package:flutter/cupertino.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

class PermissionsHelper {
  Future<void> grantAllVisiblePermissions(
    PatrolIntegrationTester $, {
    int maxAttempts = 3,
    bool isCI = false,
  }) async {
    // In CI, use shorter timeouts and fewer attempts since permissions should be pre-granted
    final timeout =
        isCI ? const Duration(milliseconds: 300) : const Duration(seconds: 2);
    final attempts = isCI ? 2 : maxAttempts;

    debugPrint(
      'PermissionsHelper: Starting permission check (CI mode: $isCI, max attempts: $attempts)',
    );

    // Try up to N times to handle multiple permission dialogs
    for (var i = 0; i < attempts; i++) {
      try {
        final visible = await $.native.isPermissionDialogVisible(
          timeout: timeout,
        );

        if (!visible) {
          debugPrint(
            'PermissionsHelper: No permission dialog visible (attempt ${i + 1}/$attempts)',
          );
          break;
        }

        debugPrint(
          'PermissionsHelper: Permission dialog detected (attempt ${i + 1}/$attempts)',
        );

        // Try multiple strategies to grant the permission
        bool granted = false;

        // Strategy 1: Use Patrol's built-in helper for "When in use"
        try {
          debugPrint('PermissionsHelper: Trying grantPermissionWhenInUse()');
          await $.native.grantPermissionWhenInUse();
          granted = true;
          debugPrint(
            'PermissionsHelper: Successfully granted via grantPermissionWhenInUse()',
          );
        } catch (e) {
          debugPrint(
            'PermissionsHelper: grantPermissionWhenInUse() failed: $e',
          );
        }

        // Strategy 2: Fall back to "Only this time" on Android 12+
        if (!granted) {
          try {
            debugPrint(
              'PermissionsHelper: Trying grantPermissionOnlyThisTime()',
            );
            await $.native.grantPermissionOnlyThisTime();
            granted = true;
            debugPrint(
              'PermissionsHelper: Successfully granted via grantPermissionOnlyThisTime()',
            );
          } catch (e) {
            debugPrint(
              'PermissionsHelper: grantPermissionOnlyThisTime() failed: $e',
            );
          }
        }

        if (!granted) {
          debugPrint(
            'PermissionsHelper: WARNING - Could not grant permission, may have been pre-granted or dialog closed',
          );
        }

        // Wait a bit for the dialog to dismiss and app to settle
        await $.pump(const Duration(milliseconds: 200));

        // Try pumpAndSettle with short timeout, but don't fail if it times out
        try {
          await $.pumpAndSettle(timeout: const Duration(seconds: 1));
        } catch (e) {
          debugPrint('PermissionsHelper: pumpAndSettle timed out: $e');
          await $.pump(const Duration(milliseconds: 200));
        }
      } catch (e) {
        debugPrint(
          'PermissionsHelper: Error checking for permission dialog: $e',
        );
        // Continue to next attempt or break if last attempt
        if (i == attempts - 1) {
          debugPrint('PermissionsHelper: Max attempts reached, continuing...');
        }
      }
    }

    debugPrint('PermissionsHelper: Permission check completed');
  }
}
