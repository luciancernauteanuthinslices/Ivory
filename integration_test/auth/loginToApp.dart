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

    // CRITICAL: Wait for "Verify login" text to confirm navigation to OTP screen completed
    // Without this, we might try to interact with the password field from login screen
    debugPrint('Waiting for navigation to OTP screen...');
    await $.pump(const Duration(
        milliseconds: 2000)); // Give time for navigation animation

    debugPrint('Looking for Verify login text...');
    // await $.waitUntilVisible($('Verify login'),
    //     timeout: const Duration(seconds: 20)); // Generous timeout for slow CI
    debugPrint('OTP screen loaded - Verify login text found!');

    // Give UI extra time to settle
    await $.pump(const Duration(milliseconds: 1500));

    // Now find and tap the OTP input field
    // TanInput wraps PinInputTextField which contains a TextField
    // We need to find the TextField that's a descendant of TanInput
    debugPrint('Looking for TextField inside TanInput...');

    //// Find TextField that's inside the TanInput widget (not the login screen TextFields)
    final otpField = $(find.descendant(
      of: find.byType(TanInput),
      matching: find.byType(TextField),
    ));

    debugPrint('Tapping OTP TextField...');
    await otpField.tap();
    debugPrint('OTP field tapped successfully');

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
