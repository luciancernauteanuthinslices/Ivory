// auth_robot.dart
import 'dart:io';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/ivory_text_field.dart';
import 'package:solarisdemo/integration_test_keys.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    debugPrint('Logging in with email: $email');
    await $(IvoryTextField).containing('Email address').enterText(email);
    await $(IvoryTextField).containing('Password').enterText(password);

    //scroll and tap the Continue button
    debugPrint('Scrolling and tapping Continue button...');
    await $.scrollUntilVisible(
      finder: $(find.byType(Button)),
      view: $(find.byType(Scrollable)),
      delta: 100,
      maxScrolls: 10,
    );

    debugPrint('Continue button scrolled into view');
    await $("Continue").tap();

    // Give more time for navigation to complete in CI (slower than local)
    await $.pump(const Duration(milliseconds: 2000));

    // If Permissions dialog is displayed, Allow notification permission
    if ($(find.byType(AlertDialog)).exists) {
      await $.native.grantPermissionWhenInUse();
    }

    // Wait for app to transition to OTP screen
    // and locally via adb commands, so no need to handle permission dialogs here
    debugPrint('Waiting for OTP screen to appear...');

    // Wait for "Verify login" text to confirm we're on the OTP screen
    // This is more reliable than looking for EditableText which may exist from previous screen
    await $.waitUntilVisible($('Verify login'),
        timeout: const Duration(seconds: 15)); // Increased timeout for CI
    debugPrint('OTP screen loaded ("Verify login" text found)');

    // Give UI time to settle and layout to complete (fixes RenderFlex overflow in CI)
    await $.pump(const Duration(milliseconds: 1500));

    // Scroll to ensure OTP input is visible (handles layout overflow in CI)
    debugPrint('Scrolling to OTP input field...');
    try {
      await $.scrollUntilVisible(
        finder: $(find.byType(EditableText)),
        view: $(find.byType(Scrollable)),
        delta: 100,
        maxScrolls: 10,
      );
      debugPrint('OTP field scrolled into view');
    } catch (e) {
      debugPrint('Scroll not needed or failed: $e, continuing...');
    }

    // Additional pump to ensure scroll animation completes
    await $.pump(const Duration(milliseconds: 500));

    // Now tap the OTP input field
    debugPrint('Tapping OTP field...');
    final otpField = $(find.byType(EditableText))
        .last; // Use .last to get the OTP field, not login fields
    await otpField.tap();
    await $.pump(const Duration(milliseconds: 500));

    // Enter OTP code - controller listener will enable button
    debugPrint('Entering OTP code...');
    await otpField.enterText('212212');

    // Wait for state to update after text entry
    debugPrint('Waiting for OTP confirmation button...');
    await $.pump(const Duration(milliseconds: 1000));

    await $(keys.loginPage.otpConfirmButton).tap();

    // Assert we are on Home Page
    await $.waitUntilVisible($('Welcome Doe!'));
    expect($('Welcome Doe!'), findsOneWidget);
  }
}
