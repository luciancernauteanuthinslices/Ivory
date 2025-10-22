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
      })  : email = email ?? (dotenv.env['EMAIL'] ?? ''),
        password = password ?? (dotenv.env['PASSWORD'] ?? '');

  /// Load test credentials from .patrol.env and override specific values
  /// This keeps all main .env values and only overrides EMAIL and PASSWORD
  static Future<void> loadPatrolEnv() async {
    try {
      final file = File('integration_test/.patrol.env');

      final lines = await file.readAsLines();
      
      // Parse only EMAIL and PASSWORD from .patrol.env
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        
        if (trimmed.contains('=')) {
          final parts = trimmed.split('=');
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          
          // Only override credentials, not app config
          if (key == 'EMAIL' || key == 'PASSWORD') {
            dotenv.env[key] = value;
          }
        }
      }
      // ignore: avoid_print
      print('✅ Loaded test credentials from .patrol.env (EMAIL: ${dotenv.env['EMAIL']})');
    } catch (e) {
      // ignore: avoid_print
      print('⚠️  Error loading .patrol.env: $e');
    }
  }
  
  Future<void> login() async {
    // Debug: Show which credentials are being used
    // ignore: avoid_print
    final atIndex = email.indexOf('@');
    final maskedEmail = email.isNotEmpty && atIndex > 3
        ? email.replaceRange(3, atIndex, '***')
        : '***@***';
    print('🔐 Logging in with email: $maskedEmail');

    // expect login button to be displayed
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

    // Handle permission dialog if it appears
    if (await $.native.isPermissionDialogVisible()) {
      await $.native.grantPermissionWhenInUse();
    }

    // Verify login with OTP - wait for the screen to appear
    await $.waitUntilVisible($('Verify login'), timeout: Duration(seconds: 10));
    expect($('Verify login'), findsOneWidget);

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
