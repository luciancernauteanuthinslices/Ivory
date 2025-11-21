// auth_robot.dart
import 'dart:io';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pin_input_text_field/pin_input_text_field.dart' as pin;
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/tan_input.dart';
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

    // Scroll and tap the Continue button
    debugPrint('Scrolling to Continue button...');
    try {
      await $.scrollUntilVisible(
        finder: $("Continue"),
        view: $(find.byType(Scrollable)),
        delta: 100,
        maxScrolls: 10,
      );
      debugPrint('Continue button scrolled into view');
    } catch (e) {
      debugPrint('Scroll for Continue failed (may already be visible): $e');
    }

    debugPrint('Tapping Continue button...');
    await $("Continue").tap();

    debugPrint('Continue button tapped successfully');

    // Wait and check for navigation or errors
    debugPrint('Waiting for navigation to OTP screen...');
    await $.pumpAndSettle(timeout: const Duration(seconds: 5));

    // Debug: Check what's actually on screen after Continue
    debugPrint('=== Screen state after Continue tap ===');
    debugPrint(
        'Login title still visible: ${$(keys.loginPage.loginTitle).exists}');
    debugPrint(
        'Email field still visible: ${$(IvoryTextField).containing('Email address').exists}');
    debugPrint('TanInput exists: ${$(TanInput).exists}');
    debugPrint('Verify login text exists: ${$('Verify login').exists}');
    debugPrint(
        'OTP field key exists: ${$(keys.loginPage.otpTextField).exists}');
    debugPrint('Continue button still exists: ${$("Continue").exists}');
    debugPrint('======================================');

    await $.waitUntilVisible($(keys.loginPage.otpTextField),
        timeout: const Duration(seconds: 20));

    final otpField = $(keys.loginPage.otpTextField);
    await otpField.tap();

    await otpField.enterText('212212');

    await $.pump(const Duration(milliseconds: 1500));

    // Wait for state to update after text entry
    debugPrint('Waiting for OTP confirmation button...');

    await $(keys.loginPage.otpConfirmButton).tap();

    // Assert we are on Home Page
    await $.waitUntilVisible($(keys.homeScreen.welcomeTitle),
        timeout: const Duration(seconds: 20));
    expect($(keys.homeScreen.welcomeTitle), findsOneWidget);

    //end of login flow
  }
}
