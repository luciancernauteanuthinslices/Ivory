import 'package:patrol/patrol.dart';
import 'package:solarisdemo/integration_test_keys.dart';
import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';
import 'package:test/test.dart' hide expect;
import 'build_app/test_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  patrolTest('Simple login test',
      tags: ['smoke'],
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
      ($) async {
    //build app for test
    final app = await buildTestApp();

    await $.pumpWidgetAndSettle(app, timeout: const Duration(seconds: 20));
    final bottomActionButtons = BottomActionButtons($);

    //login to app
    await LoginToApp($).login();
  });
}
