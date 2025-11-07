import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarisdemo/widgets/app_toolbar.dart';
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/ivory_list_tile.dart';

import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'build_app/test_app.dart';
import 'pages/repaymentsPage/repaymentsActions.dart';

void registerTests() {
  patrolTest('Repayment rate is saved correctly',
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
    await $("Automatic repayment").at(1).tap();

    await $(IvoryListTile).containing("Manage repayment settings").tap();
    expect($("Change repayment rate"), findsOneWidget);

    await repaymentsAction.tapChangeRepaymentRate();

    await $(find.widgetWithText(InkWell, 'Percentage rate repayment')).tap();
    // await $(find.widgetWithText(InkWell, 'Fixed rate repayment')).tap();

    // Find the slider
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);

    // Slider range is [10, 50] -> normalized position for 40 is 0.73
    final sliderRect = $.tester.getRect(sliderFinder);
    final double normalized = 0.73;
    final Offset tapPosition = Offset(
      sliderRect.left + sliderRect.width * normalized,
      sliderRect.center.dy,
    );

    // Tap at the computed position
    await $.tester.tapAt(tapPosition);

    //timeout 2s
    await $.pumpAndSettle(timeout: const Duration(seconds: 2));

    // Add a small delay to ensure UI is fully settled
    await Future.delayed(const Duration(milliseconds: 500));

    await $('Save changes').waitUntilVisible().tap();

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
