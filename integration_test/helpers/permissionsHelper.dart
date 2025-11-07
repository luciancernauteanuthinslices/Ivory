// call early in each test (or in a setUpAll that launches the screen)

import 'package:patrol/patrol.dart';

class PermissionsHelper {
  Future<void> grantAllVisiblePermissions(PatrolIntegrationTester $) async {
    for (var i = 0; i < 3; i++) {
      final visible = await $.native.isPermissionDialogVisible(
        timeout: const Duration(seconds: 4),
      );
      if (!visible) break;

      // Prefer "When in use"; fall back to "Only this time" on Android 12+
      try {
        await $.native.grantPermissionWhenInUse();
      } catch (_) {
        try {
          await $.native.grantPermissionOnlyThisTime();
        } catch (_) {}
      }

      await $.pump(const Duration(milliseconds: 150));
    }
  }
}
