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
import 'package:solarisdemo/redux/app_state.dart';
import 'package:solarisdemo/redux/auth/auth_state.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:solarisdemo/models/auth/auth_error_type.dart';

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

  /// Check if authentication was successful by verifying access token exists
  Future<bool> hasAccessToken() async {
    try {
      // Get the Redux store from the widget tree
      final context =
          $.tester.element(find.byType(StoreProvider<AppState>).first);
      final store = StoreProvider.of<AppState>(context);
      final authState = store.state.authState;

      if (authState is AuthenticationInitializedState) {
        final accessToken =
            authState.cognitoUser.session.getAccessToken().getJwtToken();
        if (accessToken != null && accessToken.isNotEmpty) {
          debugPrint(
              '✅ Access token obtained: ${accessToken.substring(0, 50)}...');
          return true;
        }
      }

      debugPrint(
          '❌ No access token found. Auth state: ${authState.runtimeType}');

      // Log specific error if AuthErrorState
      if (authState is AuthErrorState) {
        debugPrint('🔴 Authentication error type: ${authState.errorType}');
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking access token: $e');
      return false;
    }
  }

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

    debugPrint('Tapping Continue button...');
    await $("Continue").tap();

    debugPrint('Continue button tapped successfully');

    // Wait for authentication to complete
    // Note: Using pump instead of pumpAndSettle because there may be continuous animations
    debugPrint('Waiting for authentication to complete...');
    for (int i = 0; i < 10; i++) {
      await $.pump(const Duration(milliseconds: 500));
      debugPrint('Pump iteration $i - checking for OTP screen...');

      // Check if OTP screen appeared
      if ($('Verify login').exists) {
        debugPrint('✅ OTP screen detected!');
        break;
      }

      // Check if still on login screen with error
      if ($(keys.loginPage.loginTitle).exists && i > 4) {
        debugPrint('⚠️  Still on login screen after ${i * 0.5} seconds');
      }
    }

    // Check if we have an access token (indicates successful authentication)
    debugPrint('=== Checking authentication status ===');
    final hasToken = await hasAccessToken();
    debugPrint('Has access token: $hasToken');

    // ASSERTION: Verify that authentication succeeded and we navigated to OTP screen
    if (!hasToken) {
      debugPrint('❌ AUTHENTICATION FAILED - Cannot proceed to OTP screen');
      debugPrint(
          'Login title still visible: ${$(keys.loginPage.loginTitle).exists}');
      debugPrint('OTP screen visible: ${$('Verify login').exists}');

      throw Exception('Authentication failed after tapping Continue. '
          'Expected to navigate to OTP screen but still on login screen. '
          'Check test credentials in .env or CI environment variables.');
    }

    // Assert that we successfully navigated to OTP screen
    debugPrint('✅ Authentication succeeded - verifying OTP screen is visible');
    expect($('Verify login').exists, true,
        reason:
            'Expected to navigate to OTP screen after successful authentication');

    await $.waitUntilVisible($(keys.loginPage.otpTextField),
        timeout: const Duration(seconds: 10));

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
