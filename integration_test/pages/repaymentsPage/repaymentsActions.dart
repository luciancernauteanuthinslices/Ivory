import 'package:patrol/patrol.dart'; // Patrol ($, patrolTest, PatrolFinder)
import 'package:flutter_test/flutter_test.dart'; // Keys, matchers, pump*, etc.
import 'package:flutter/material.dart'; // Icons, if you use byIcon

class RepaymentsActions {
  final PatrolIntegrationTester $;
  RepaymentsActions(this.$);

  PatrolFinder get changeRepaymentRate => $(Icons.sync);
  PatrolFinder get setRepaymentReminder =>
      $(Icons.notifications_active_outlined);
  PatrolFinder get viewBills => $(Icons.content_paste_search_rounded);
  PatrolFinder get repaymentAnalytics => $(Icons.analytics_outlined);
  PatrolFinder get needMoreCredit => $(Icons.back_hand_outlined);

  Future<void> tapChangeRepaymentRate() async {
    await changeRepaymentRate.tap();
  }

  Future<void> tapSetRepaymentReminder() async {
    await setRepaymentReminder.tap();
  }

  Future<void> tapViewBills() async {
    await viewBills.tap();
  }

  Future<void> tapRepaymentAnalytics() async {
    await repaymentAnalytics.tap();
  }

  Future<void> tapNeedMoreCredit() async {
    await needMoreCredit.tap();
  }
}
