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
               (const String.fromEnvironment('PATROL_EMAIL', defaultValue: '') != '' 
                 ? const String.fromEnvironment('PATROL_EMAIL')
                 : dotenv.env['EMAIL'] ?? ''),
        password = password ?? 
               (const String.fromEnvironment('PATROL_PASSWORD', defaultValue: '') != ''
                 ? const String.fromEnvironment('PATROL_PASSWORD')
                 : dotenv.env['PASSWORD'] ?? '');
  
  Future<void> login() async {
    // Validate credentials are loaded
    if (email.isEmpty || password.isEmpty) {
      // ignore: avoid_print
      print('❌ EMAIL: "$email" (length: ${email.length})');
      // ignore: avoid_print
      print('❌ PASSWORD: ${password.isEmpty ? "empty" : "***"} (length: ${password.length})');
      // ignore: avoid_print
      print('❌ PATROL_EMAIL env: "${const String.fromEnvironment('PATROL_EMAIL', defaultValue: 'NOT_SET')}"');
      // ignore: avoid_print
      print('❌ dotenv EMAIL: "${dotenv.env['EMAIL'] ?? 'NOT_SET'}"');
      throw Exception('❌ Test credentials not loaded! Checked: --dart-define PATROL_EMAIL/PATROL_PASSWORD and .env file');
    }
    
    // Debug: Show which credentials are being used (safely)
    // ignore: avoid_print
    final maskedEmail = email.length > 3 && email.contains('@')
        ? email.replaceRange(3, email.indexOf('@'), '***')
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

    // Wait for OTP screen to appear
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
