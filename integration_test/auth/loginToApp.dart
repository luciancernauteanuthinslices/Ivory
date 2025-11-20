// auth_robot.dart
import 'dart:io';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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
    await $("Continue").tap();

    // Wait for app to transition to OTP screen
    // Permissions are pre-granted in CI via grant_permissions.sh
    // and locally via adb commands, so no need to handle permission dialogs here
    debugPrint('Waiting for OTP screen to appear...');
    await $.pump(const Duration(milliseconds: 2000));

    // Wait for OTP input field to be visible and tappable
    debugPrint('Looking for OTP input field...');
    try {
      await $.waitUntilVisible($(find.byType(EditableText)),
          timeout: const Duration(seconds: 15));
      debugPrint('OTP field is visible');
    } catch (e) {
      debugPrint('Failed to find visible OTP field: $e');
      // Try to pump a few more times to let UI settle
      for (int i = 0; i < 3; i++) {
        await $.pump(const Duration(milliseconds: 500));
      }
    }

    // Tap on the OTP input area to focus it
    debugPrint('Tapping OTP field...');
    final otpField = $(find.byType(EditableText)).first;
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
