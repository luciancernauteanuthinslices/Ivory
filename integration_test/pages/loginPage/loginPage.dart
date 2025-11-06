import 'package:patrol/patrol.dart'; // Patrol ($, patrolTest, PatrolFinder)
import 'package:flutter_test/flutter_test.dart'; // Keys, matchers, pump*, etc.
import 'package:flutter/material.dart'; // Icons, if you use byIcon

class LoginPage {
  final PatrolIntegrationTester $;
  LoginPage(this.$);

  PatrolFinder get home => $(Icons.home);
  PatrolFinder get cards => $(Icons.credit_card_outlined);
  PatrolFinder get transactions => $(Icons.payments_outlined);
  PatrolFinder get settings => $(Icons.settings_outlined);

  Future<void> tapHome() async {
    await home.tap();
  }

  Future<void> tapCards() async {
    await cards.tap();
  }

  Future<void> tapTransactions() async {
    await transactions.tap();
  }

  Future<void> tapSettings() async {
    await settings.tap();
  }
}
