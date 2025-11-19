import 'package:patrol/patrol.dart';
import 'package:solarisdemo/integration_test_keys.dart';
import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
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

    // Find an active card (one that has a freeze button) by swiping through the PageView
    // Card 6368 is the target, but if not available/active, we'll find any active card
    final pageView = find.byType(PageView);
    await $.waitUntilVisible($(pageView));

    // Get the actual PageView widget's size from its RenderBox
    final RenderBox pageViewBox = $.tester.renderObject(pageView);
    final Size pageViewSize = pageViewBox.size;
    // Swipe 80% of the widget's width for reliable page transition
    final double swipeDistance = pageViewSize.width * 0.8;

    // Swipe through cards until we find card 6368 OR any card with a freeze button
    bool targetCardFound = false;
    bool activeCardFound = false;
    int maxSwipes = 20; // Prevent infinite loop
    int swipeCount = 0;

    while (!activeCardFound && swipeCount < maxSwipes) {
      // First, check if our target card 6368 is currently visible
      final numberText = find.textContaining('6368', findRichText: true);
      if ($(numberText).exists) {
        targetCardFound = true;
        print(
            '✅ Found card with last four digits 6368 after $swipeCount swipes');
      }

      // Wait for CardActions to potentially load
      await $.pump(Duration(milliseconds: 500));

      // Check if the current card has a freeze button (meaning it's ACTIVE)
      final freezeButton = $(keys.cardActions.freezeCardButton);
      if (freezeButton.exists) {
        activeCardFound = true;
        print(
            '✅ Found active card with freeze button after $swipeCount swipes');
        break;
      }

      // If we haven't found an active card, swipe to the next one
      print(
          '⏩ Swiping left (attempt ${swipeCount + 1}) - swipe distance: $swipeDistance px');
      await $.tester.drag($(pageView), Offset(-swipeDistance, 0));
      await $.pumpAndSettle(timeout: Duration(seconds: 2));
      swipeCount++;
    }

    expect(activeCardFound, true,
        reason:
            'No active card with freeze button found after $swipeCount swipes');

    if (targetCardFound && activeCardFound) {
      print('✅ Successfully found target card 6368 and it is ACTIVE');
    } else if (activeCardFound) {
      print('⚠️  Card 6368 not found or not active, using another active card');
    }

    // Ensure the freeze button is visible and ready
    await $.waitUntilVisible($(keys.cardActions.freezeCardButton),
        timeout: Duration(seconds: 5));

    // Freeze card - scroll to the button and tap it
    await $(keys.cardActions.freezeCardButton).scrollTo().tap();

    //expect subtitle "If your card is compromised" to be visible
    final ifYourCardIsCompromised = $('If your card is compromised');
    await $.waitUntilExists(ifYourCardIsCompromised);

    //UnfreezeCard
    await $(keys.cardActions.unFreezeCardButton).tap();

    //expect subtitle "If your card is compromised" to disappear after unfreezing
    await $.pumpAndSettle(timeout: Duration(seconds: 3));
    expect(ifYourCardIsCompromised, findsNothing);
  });
}
