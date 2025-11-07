import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarisdemo/models/repayments/reminder/repayment_reminder.dart';
import 'package:solarisdemo/widgets/app_toolbar.dart';
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/ivory_list_tile.dart';

import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'build_app/test_app.dart';
import 'pages/repaymentsPage/repaymentsActions.dart';
import 'package:solarisdemo/screens/repayments/repayment_reminder.dart';

void registerTests() {
  patrolTest('Repayment reminder is saved correctly',
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
    final app = await buildTestApp();
    await $.pumpWidgetAndSettle(app);
    final bottomActionButtons = BottomActionButtons($);
    final repaymentsAction = RepaymentsActions($);

    //login to app
    await LoginToApp($).login();
    // Tap the "Transactions" button
    await bottomActionButtons.tapTransactions();

    await $("Upcoming").tap();

    //tap on second 'Automatic repayment'
    await $("Automatic repayment").at(0).tap();

    await $(IvoryListTile).containing("Manage repayment settings").tap();
    expect($("Set repayment reminder"), findsOneWidget);

    await repaymentsAction.tapSetRepaymentReminder();

    await $(Text).containing('Add reminder').tap();

    expect($('1 hour before'), findsOneWidget);

    await $('1 hour before').tap();

    await $.pumpAndSettle();
    await $(Button).containing('Save').tap();

    expect($("Repayment successfully changed!"), findsOneWidget);

    expect(
        $(find
            .textContaining('You will start paying a percentage rate of 40%')),
        findsOneWidget);
  });
}

void main() {
  registerTests();
}
