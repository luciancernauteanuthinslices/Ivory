import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/ivory_list_tile.dart';

import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'build_app/test_app.dart';
import 'pages/repaymentsPage/repaymentsActions.dart';

void main() {
  patrolTest(
    'Repayment reminder is saved correctly',
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

      await $("Upcoming").tap();

      //tap on second 'Automatic repayment'
      await $("Automatic repayment").at(0).tap();

      await $(IvoryListTile).containing("Manage repayment settings").tap();
      await $.pumpAndSettle();
      expect($("Set repayment reminder"), findsOneWidget);

      await repaymentsAction.tapSetRepaymentReminder();

      await $(Text).containing('Add reminder').tap();

      expect($('1 hour before'), findsOneWidget);

      //taps the '1 hour before' reminder with finding the ancestor class of the text
      await $(
        find.ancestor(
          of: find.text('1 hour before'),
          matching: find.byType(
            InkWell,
          ), // or ListTile if that’s what it builds
        ),
      ).scrollTo().tap();

      await $.pumpAndSettle();
      await $(Button).containing('Save').tap();

      //check if reminder is saved
      expect($("Set repayment reminder"), findsOneWidget);
      await repaymentsAction.tapSetRepaymentReminder();

      expect(
        find.ancestor(
          of: find.text('1 hour before'),
          matching: find.byType(
            ListTile,
          ), // or ListTile if that’s what it builds
        ),
        findsOneWidget,
      );

      await $.pumpAndSettle();

      //delete reminder
      await $(find.byIcon(Icons.delete_outline).at(0)).scrollTo().tap();

      await $(Button).containing('Yes, remove reminder').tap();

      await $.pumpAndSettle();

      //expect reminder is deleted
      await $.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.text('1 hour before'),
          matching: find.byType(
            ListTile,
          ), // or ListTile if that’s what it builds
        ),
        findsNothing,
      );
    },
  );
}
