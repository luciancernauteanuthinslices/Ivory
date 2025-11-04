import 'package:patrol/patrol.dart';
import 'package:solarisdemo/integration_test_keys.dart';
import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'package:test/test.dart' hide expect;
import 'build_app/test_app.dart';
import 'package:flutter_test/flutter_test.dart';



void registerTests() {
  patrolTest('Check if virtual card can be frozen and unfrozen',
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive, ($) async {

    //build app for test
    final app = await buildTestApp();
    
    await $.pumpWidgetAndSettle(app);
    final bottomActionButtons = BottomActionButtons($);

    //login to app
    await LoginToApp($).login();

    // Tap by label
    await bottomActionButtons.tapCards();

    // Give some time for navigation but don't wait indefinitely
    await $.pump(Duration(milliseconds: 500));

    //expect we are on Cards page  
    await $.waitUntilVisible($(keys.cardsPage.cardsPageTitle), timeout: Duration(seconds: 10));

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

void main() {
  registerTests();
}