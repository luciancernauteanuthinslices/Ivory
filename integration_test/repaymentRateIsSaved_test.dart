import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:solarisdemo/config.dart';
import 'package:solarisdemo/firebase_options.dart';
import 'package:solarisdemo/infrastructure/auth/auth_service.dart';
import 'package:solarisdemo/infrastructure/bank_card/bank_card_service.dart';
import 'package:solarisdemo/infrastructure/categories/categories_service.dart';
import 'package:solarisdemo/infrastructure/change_request/change_request_service.dart';
import 'package:solarisdemo/infrastructure/credit_line/credit_line_service.dart';
import 'package:solarisdemo/infrastructure/device/biometrics_service.dart';
import 'package:solarisdemo/infrastructure/device/device_binding_service.dart';
import 'package:solarisdemo/infrastructure/device/device_fingerprint_service.dart';
import 'package:solarisdemo/infrastructure/device/device_service.dart';
import 'package:solarisdemo/infrastructure/documents/documents_service.dart';
import 'package:solarisdemo/infrastructure/documents/file_saver_service.dart';
import 'package:solarisdemo/infrastructure/mobile_number/mobile_number_service.dart';
import 'package:solarisdemo/infrastructure/notifications/push_notification_service.dart';
import 'package:solarisdemo/infrastructure/notifications/push_notification_service_provider.dart';
import 'package:solarisdemo/infrastructure/notifications/push_notification_storage_service.dart';
import 'package:solarisdemo/infrastructure/onboarding/card_configuration/onboarding_card_configuration_service.dart';
import 'package:solarisdemo/infrastructure/onboarding/financial_details/onboarding_financial_details_service.dart';
import 'package:solarisdemo/infrastructure/onboarding/identity_verification/onboarding_identity_verification_service.dart';
import 'package:solarisdemo/infrastructure/onboarding/onboarding_service.dart';
import 'package:solarisdemo/infrastructure/onboarding/personal_details/onboarding_personal_details_service.dart';
import 'package:solarisdemo/infrastructure/onboarding/signup/onboarding_signup_service.dart';
import 'package:solarisdemo/infrastructure/person/account_summary/account_summary_service.dart';
import 'package:solarisdemo/infrastructure/person/person_service.dart';
import 'package:solarisdemo/infrastructure/repayments/bills/bill_service.dart';
import 'package:solarisdemo/infrastructure/repayments/change_repayment/change_repayment_service.dart';
import 'package:solarisdemo/infrastructure/repayments/more_credit/more_credit_service.dart';
import 'package:solarisdemo/infrastructure/repayments/reminder/repayment_reminder_service.dart';
import 'package:solarisdemo/infrastructure/suggestions/address/address_suggestions_service.dart';
import 'package:solarisdemo/infrastructure/suggestions/city/city_suggestions_service.dart';
import 'package:solarisdemo/infrastructure/transactions/transaction_service.dart';
import 'package:solarisdemo/infrastructure/transfer/transfer_service.dart';
import 'package:solarisdemo/ivory_app.dart';
import 'package:solarisdemo/redux/app_state.dart';
import 'package:solarisdemo/redux/store_factory.dart';
import 'package:solarisdemo/utilities/device_info/device_info.dart';

import 'auth/loginToApp.dart';
import 'pages/bottomActionBar/bottomActionButtons.dart';


void main() {
  patrolTest('Repayment rate is saved correctly',
      framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive, ($) async {
        // Load environment variables (API config from main .env)
        await dotenv.load();

        // Get client configuration
        final clientConfig = ClientConfig.getClientConfig();

        // Initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Set preferred orientations
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        // Initialize push notification service only if not already initialized
        // This prevents "Stream has already been listened to" errors in hot restart/develop mode
        if (!PushNotificationServiceProvider.instance.isInitialized) {
          PushNotificationServiceProvider.init(FirebasePushNotificationService(
            storageService: PushNotificationSharedPreferencesStorageService(),
          ));
        }

        final pushNotificationService = PushNotificationServiceProvider.instance.service;

        // Create the store with all required services
        final store = createStore(
          initialState: AppState.initialState(),
          pushNotificationService: pushNotificationService,
          transactionService: TransactionService(),
          creditLineService: CreditLineService(),
          repaymentReminderService: RepaymentReminderService(),
          cardApplicationService: CardApplicationService(),
          billService: BillService(),
          moreCreditService: MoreCreditService(),
          bankCardService: BankCardService(),
          categoriesService: CategoriesService(),
          personService: PersonService(),
          transferService: TransferService(),
          changeRequestService: ChangeRequestService(),
          deviceBindingService: DeviceBindingService(),
          deviceService: DeviceService(),
          biometricsService: BiometricsService(),
          deviceInfoService: DeviceInfoService(),
          accountSummaryService: AccountSummaryService(),
          deviceFingerprintService: DeviceFingerprintService(),
          authService: AuthService(),
          onboardingService: OnboardingService(),
          onboardingSignupService: OnboardingSignupService(),
          citySuggestionsService: CitySuggestionsService(),
          addressSuggestionsService: AddressSuggestionsService(),
          onboardingFinancialDetailsService: OnboardingFinancialDetailsService(),
          onboardingPersonalDetailsService: OnboardingPersonalDetailsService(),
          mobileNumberService: MobileNumberService(),
          documentsService: DocumentsService(),
          fileSaverService: FileSaverService(),
          onboardingIdentityVerificationService: OnbordingIdentityVerificationService(),
          onboardingCardConfigurationService: OnboardingCardConfigurationService(),
        );

        // Pump the IvoryApp widget
        await $.pumpWidgetAndSettle(
          IvoryApp(
            clientConfig: clientConfig,
            store: store,
          ),
        );
        final bottomActionButtons = BottomActionButtons($);
        //login to app
        await LoginToApp($).login();
        // Tap the "Transactions" button
        await bottomActionButtons.tapTransactions();

      });
}