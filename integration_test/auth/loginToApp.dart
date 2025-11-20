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
import '../helpers/ciDetection.dart';

class LoginToApp {
  final PatrolIntegrationTester $;
  final String email;
  final String password;

  LoginToApp(this.$, {String? email, String? password})
    : email =
          email ??
          (const String.fromEnvironment('PATROL_EMAIL', defaultValue: '') != ''
              ? const String.fromEnvironment('PATROL_EMAIL')
              : dotenv.env['EMAIL'] ?? ''),
      password =
          password ??
          (const String.fromEnvironment('PATROL_PASSWORD', defaultValue: '') !=
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
    await $.waitUntilVisible(
      $(keys.welcomeScreen.logInButton),
      timeout: Duration(seconds: 10),
    );
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
    final isCI = CIDetection.isCI;
    final ciPlatform = CIDetection.ciPlatform;

    if (isCI) {
      debugPrint('🤖 Running in CI environment: $ciPlatform');
      debugPrint('📋 Permissions should be pre-granted');
    } else {
      debugPrint('💻 Running locally');
    }

    debugPrint('🔍 Checking for permission dialogs...');

    // Give the app a moment to show any permission dialogs
    await $.pump(const Duration(milliseconds: 1000));

    // Try to handle permission dialogs with multiple strategies
    int maxAttempts = isCI ? 3 : 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        debugPrint(
          '🔄 Attempt ${attempt + 1}/$maxAttempts: Checking for permission dialog',
        );

        // Check if permission dialog is visible
        final hasDialog = await $.native.isPermissionDialogVisible(
          timeout: const Duration(milliseconds: 500),
        );

        if (!hasDialog) {
          debugPrint('✅ No permission dialog detected');
          break;
        }

        debugPrint('⚠️  Permission dialog detected! Attempting to grant...');

        // Strategy 1: Try grantPermissionWhenInUse
        try {
          await $.native.grantPermissionWhenInUse();
          debugPrint('✅ Granted permission via grantPermissionWhenInUse');
          await $.pump(const Duration(milliseconds: 500));
          continue;
        } catch (e) {
          debugPrint('❌ grantPermissionWhenInUse failed: $e');
        }

        // Strategy 2: Try grantPermissionOnlyThisTime (Android 12+)
        try {
          await $.native.grantPermissionOnlyThisTime();
          debugPrint('✅ Granted permission via grantPermissionOnlyThisTime');
          await $.pump(const Duration(milliseconds: 500));
          continue;
        } catch (e) {
          debugPrint('❌ grantPermissionOnlyThisTime failed: $e');
        }

        // Strategy 3: Try to tap "Allow" button directly with native tap
        if (Platform.isIOS) {
          try {
            debugPrint('📱 iOS: Trying to tap Allow button');
            await $.native.tap(Selector(text: 'Allow'));
            debugPrint('✅ Tapped Allow button');
            await $.pump(const Duration(milliseconds: 500));
            continue;
          } catch (e) {
            debugPrint('❌ Failed to tap Allow button: $e');
          }
        } else if (Platform.isAndroid) {
          try {
            debugPrint('🤖 Android: Trying to tap Allow button');
            // Try different permission button texts
            final allowTexts = [
              'Allow',
              'ALLOW',
              'While using the app',
              'Only this time',
            ];
            for (final text in allowTexts) {
              try {
                await $.native.tap(Selector(text: text));
                debugPrint('✅ Tapped "$text" button');
                await $.pump(const Duration(milliseconds: 500));
                break;
              } catch (e) {
                // Try next text
              }
            }
          } catch (e) {
            debugPrint('❌ Failed to tap permission button: $e');
          }
        }

        // Wait a bit before next attempt
        await $.pump(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('❌ Error in permission handling attempt ${attempt + 1}: $e');
        // Continue to next attempt
      }
    }

    debugPrint('🏁 Permission handling complete, proceeding with test');

    // Give app time to settle after permission handling
    await $.pump(const Duration(milliseconds: 1000));

    // Try pumpAndSettle but don't fail if it times out
    try {
      await $.pumpAndSettle(timeout: const Duration(seconds: 3));
      debugPrint('✅ App settled successfully');
    } catch (e) {
      debugPrint('⚠️  pumpAndSettle timed out (continuing anyway): $e');
      // Just pump a few times to let UI update
      for (int i = 0; i < 5; i++) {
        await $.pump(const Duration(milliseconds: 200));
      }
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
