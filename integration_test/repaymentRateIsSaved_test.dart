import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/ivory_list_tile.dart';

import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'build_app/test_app.dart';
import 'pages/repaymentsPage/repaymentsActions.dart';
import 'helpers/sliderHelper.dart';

void main() {
  patrolTest(
    'Repayment rate is saved correctly',
    tags: ['regression'],
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

      // await $("Upcoming").tap();
      await $("Upcoming").tap(); // intentionally fails

      //tap on second 'Automatic repayment'
      await $("Automatic repayment").at(1).tap();

      await $(IvoryListTile).containing("Manage repayment settings").tap();

      // Wait for the text to appear in the UI
      await $.pumpAndSettle();
      expect($('Change repayment rate'), findsOneWidget);

      await repaymentsAction.tapChangeRepaymentRate();

      await $(find.widgetWithText(InkWell, 'Percentage rate repayment')).tap();
      // await $(find.widgetWithText(InkWell, 'Fixed rate repayment')).tap();

      // Find the slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Move slider to 40% using helper (works for any min/max)
      await setSliderToPercent(
        $,
        slider: sliderFinder,
        targetPercent: 40,
        min: 10,
        max: 50,
      );

      //timeout 2s
      await $.pumpAndSettle(timeout: const Duration(seconds: 2));

      // Add a small delay to ensure UI is fully settled
      await Future.delayed(const Duration(milliseconds: 500));

      await $(find.widgetWithText(Button, 'Save changes')).scrollTo().tap();
      await $.pumpAndSettle();

// Success paragraph: match by content (don’t hardcode the exact percent)
      expect(
        $(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                (w.text as TextSpan).toPlainText().contains(
                      'You will start paying a percentage rate of ',
                    ) &&
                (w.text as TextSpan).toPlainText().contains('40%'),
          ),
        ),
        findsOneWidget,
      );
    },
  );
}
