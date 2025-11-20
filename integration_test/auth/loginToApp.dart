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
    await $(IvoryTextField).containing('Email address').enterText(email);
    await $(IvoryTextField).containing('Password').enterText(password);
    await $("Continue").tap();

    // Handle permission dialogs that may appear after login
    // Pre-granted in CI, but may still appear locally or if app was reinstalled
    // Use a shorter timeout and fewer retries since permissions should be pre-granted in CI

    // debugPrint('Checking for permission dialogs...');
    // // Try to grant the permission
    // try {
    //   await $.native.grantPermissionWhenInUse();
    //   debugPrint('Successfully granted permission');
    // } catch (e) {
    //   debugPrint(
    //       'Failed to grant permission: $e, trying alternative methods...');
    //   try {
    //     await $.native.grantPermissionOnlyThisTime();
    //     debugPrint('Successfully granted permission (only this time)');
    //   } catch (e2) {
    //     debugPrint('All permission grant methods failed: $e2');
    //   }
    // }

    // // Give app minimal time to settle after permissions
    // await $.pump(const Duration(milliseconds: 500));

    // Try pumpAndSettle with a short timeout, but don't fail if it times out
    // try {
    //   await $.pumpAndSettle(timeout: const Duration(seconds: 2));
    // } catch (e) {
    //   debugPrint('pumpAndSettle timed out (expected in some cases): $e');
    //   await $.pump(const Duration(milliseconds: 500));
    // }

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
