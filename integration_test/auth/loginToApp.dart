// auth_robot.dart
import 'dart:io';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:solarisdemo/widgets/ivory_text_field.dart';
import 'package:solarisdemo/integration_test_keys.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../helpers/permissionsHelper.dart';

class LoginToApp {
  final PatrolIntegrationTester $;
  final String email;
  final String password;

  LoginToApp(
    this.$, {
    String? email,
    String? password,
  })  : email = email ??
            (const String.fromEnvironment('PATROL_EMAIL', defaultValue: '') !=
                    ''
                ? const String.fromEnvironment('PATROL_EMAIL')
                : dotenv.env['EMAIL'] ?? ''),
        password = password ??
            (const String.fromEnvironment('PATROL_PASSWORD',
                        defaultValue: '') !=
                    ''
                ? const String.fromEnvironment('PATROL_PASSWORD')
                : dotenv.env['PASSWORD'] ?? '');

  Future<void> login() async {
    // Try to navigate back to welcome screen if we're not there already
    // This handles cases where previous tests left the app in a different state
    int retries = 0;
    while (!$(keys.welcomeScreen.logInButton).exists && retries < 5) {
      try {
        await $.native.pressBack();
        await $.pumpAndSettle(timeout: Duration(seconds: 2));
      } catch (e) {
        // Ignore errors during back navigation
      }
      retries++;
    }

    // Now wait for the login button to be displayed
    await $.waitUntilVisible($(keys.welcomeScreen.logInButton),
        timeout: Duration(seconds: 10));
    expect($(keys.welcomeScreen.logInButton), findsOneWidget);

    // Tap on the "Log in" button
    await $(keys.welcomeScreen.logInButton).tap();

    // Expect we are on Login Page
    await $.waitUntilVisible($(keys.loginPage.loginTitle));
    expect($(keys.loginPage.loginTitle), findsOneWidget);

    // Fill in email and password
    await $(IvoryTextField).containing('Email address').enterText(email);
    await $(IvoryTextField).containing('Password').enterText(password);
    await $("Continue").tap();

    // Handle permission dialogs that may appear after login
    // Pre-granted in CI, but may still appear locally or if app was reinstalled
    await PermissionsHelper().grantAllVisiblePermissions($);

    // Wait for any permission dialogs to fully dismiss before proceeding
    // Use a more robust waiting strategy that doesn't timeout if dialog is gone
    int waitAttempts = 0;
    while (waitAttempts < 10) {
      final hasDialog = await $.native.isPermissionDialogVisible(
        timeout: const Duration(milliseconds: 500),
      );

      if (!hasDialog) {
        // No dialog visible, break and proceed
        break;
      }

      // Dialog still visible, try granting again
      debugPrint('Permission dialog still visible, attempting to grant...');
      try {
        if (Platform.isAndroid) {
          await $.native.grantPermissionWhenInUse();
        } else if (Platform.isIOS) {
          await $.native.grantPermissionWhenInUse();
        }
      } catch (e) {
        debugPrint('Error granting permission: $e');
      }

      // Wait a bit before checking again
      await $.pump(const Duration(milliseconds: 500));
      waitAttempts++;
    }

    // Give app time to settle after permissions and navigate to OTP screen
    // Use pump with timeout instead of pumpAndSettle to avoid timeout exceptions
    await $.pump(const Duration(milliseconds: 1000));
    try {
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
    } catch (e) {
      // If pumpAndSettle times out, just pump a few more times and continue
      debugPrint('pumpAndSettle timed out, continuing anyway: $e');
      await $.pump(const Duration(milliseconds: 1000));
    }

    // Wait for OTP screen to appear
    // await $.waitUntilVisible($(find.byType(EditableText)),
    //     timeout: const Duration(seconds: 10));

    // Tap on the OTP input area to focus it
    final otpField = $(find.byType(EditableText)).first;
    await otpField.tap();
    await $.pumpAndSettle();

    // Enter OTP code - controller listener will enable button
    await otpField.enterText('212212');

    // Wait for state to update after text entry
    await $.pumpAndSettle();

    await $(keys.loginPage.otpConfirmButton).tap();

    // Assert we are on Home Page
    await $.waitUntilVisible($('Welcome Doe!'));
    expect($('Welcome Doe!'), findsOneWidget);
  }
}
