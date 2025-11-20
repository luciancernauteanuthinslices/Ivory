import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:solarisdemo/config.dart';
import 'package:solarisdemo/infrastructure/onboarding/signup/onboarding_signup_presenter.dart';
import 'package:solarisdemo/redux/app_state.dart';
import 'package:solarisdemo/widgets/animated_linear_progress_indicator.dart';
import 'package:solarisdemo/widgets/app_toolbar.dart';
import 'package:solarisdemo/widgets/button.dart';
import 'package:solarisdemo/widgets/screen_scaffold.dart';
import 'package:solarisdemo/widgets/scrollable_screen_container.dart';

class OnboardingTermConditionsScreen extends StatefulWidget {
  static const routeName = '/onboardingTermConditionsScreen';

  const OnboardingTermConditionsScreen({super.key});

  @override
  State<OnboardingTermConditionsScreen> createState() =>
      _OnboardingTermConditionsScreenState();
}

class _OnboardingTermConditionsScreenState
    extends State<OnboardingTermConditionsScreen> {
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, OnboardingSignupViewModel>(
      converter: (store) => OnboardingSignupPresenter.present(
        signupState: store.state.onboardingSignupState,
      ),
      builder: (context, viewModel) => ScreenScaffold(
        body: Column(
          children: [
            AppToolbar(
              richTextTitle: StepRichTextTitle(step: 5, totalSteps: 5),
              actions: const [AppbarLogo()],
              padding: ClientConfig.getCustomClientUiSettings()
                  .defaultScreenHorizontalPadding,
            ),
            AnimatedLinearProgressIndicator.step(current: 5, totalSteps: 5),
            Expanded(
              child: ScrollableScreenContainer(
                padding: ClientConfig.getCustomClientUiSettings()
                    .defaultScreenHorizontalPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      "Terms and Conditions",
                      style: ClientConfig.getTextStyleScheme().heading2,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Please review and accept our terms and conditions to continue.",
                      style: ClientConfig.getTextStyleScheme().bodyLargeRegular,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            "Terms and Conditions\n\n"
                            "1. Acceptance of Terms\n"
                            "By accessing and using this service, you accept and agree to be bound by the terms and provision of this agreement.\n\n"
                            "2. Use License\n"
                            "Permission is granted to temporarily use this service for personal, non-commercial transitory viewing only.\n\n"
                            "3. Disclaimer\n"
                            "The materials on this service are provided on an 'as is' basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.\n\n"
                            "4. Limitations\n"
                            "In no event shall we or our suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use this service.\n\n"
                            "5. Privacy Policy\n"
                            "Your use of our service is also governed by our Privacy Policy. Please review our Privacy Policy, which also governs the service and informs users of our data collection practices.\n\n"
                            "6. Modifications\n"
                            "We may revise these terms of service at any time without notice. By using this service you are agreeing to be bound by the then current version of these terms of service.",
                            style: ClientConfig.getTextStyleScheme()
                                .bodySmallRegular,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _termsAccepted,
                          onChanged: (value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            "I have read and accept the terms and conditions",
                            style: ClientConfig.getTextStyleScheme()
                                .bodyLargeRegular,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: "Continue",
                      onPressed: _termsAccepted
                          ? () {
                              // TODO: Dispatch action to continue onboarding
                              // Navigate to next screen
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
