import 'package:patrol/patrol.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'build_app/test_app.dart';

void registerTests() {
  patrolTest('Repayment rate is saved correctly',
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive, ($) async {
       
        final app = await buildTestApp();
        await $.pumpWidgetAndSettle(app);
        final bottomActionButtons = BottomActionButtons($);
        
        //login to app
        await LoginToApp($).login();
        // Tap the "Transactions" button
        await bottomActionButtons.tapTransactions();
      
      });
}

void main() {
  registerTests();
}