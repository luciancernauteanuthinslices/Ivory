import 'package:patrol/patrol.dart';
import 'package:solarisdemo/integration_test_keys.dart';
import 'package:solarisdemo/widgets/card_widget.dart';
import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'package:test/test.dart' hide expect;
import 'build_app/test_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  patrolTest('Check if virtual card can be frozen and unfrozen',
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
    //build app for test
    final app = await buildTestApp();

    await $.pumpWidgetAndSettle(app, timeout: const Duration(seconds: 20));
    final bottomActionButtons = BottomActionButtons($);

    //login to app
    await LoginToApp($).login();

    // Tap by label
    await bottomActionButtons.tapCards();

    // Give some time for navigation but don't wait indefinitely
    await $.pump(Duration(milliseconds: 500));

    //expect we are on Cards page
    await $.waitUntilVisible($(keys.cardsPage.cardsPageTitle),
        timeout: Duration(seconds: 10));

    //find card with number 4934
    final numberText = find.textContaining('4934', findRichText: true);

    //find card widget
    final targetCard = find.ancestor(
      of: numberText,
      matching: find.byType(BankCardWidget),
    );

    // Your cards sit inside a horizontal PageView
    // await $.scrollUntilVisible(
    //   finder: targetCard,
    //   scrollable: find.byType(PageView),
    // );

    expect(targetCard, findsOneWidget);

    //freezeCard
    await $(keys.cardActions.freezeCardButton).tap();

    //expect subtitle "If your card is compromised" to be visible
    final ifYourCardIsCompromised = $('If your card is compromised');
    await $.waitUntilExists(ifYourCardIsCompromised);

    //UnfreezeCard
    await $(keys.cardActions.unFreezeCardButton).tap();

    //expect subtitle "If your card is compromised" to not be visible
    expect(ifYourCardIsCompromised, findsNothing);
  });
}
