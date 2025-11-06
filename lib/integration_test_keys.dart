import 'package:flutter/foundation.dart';

class WelcomeScreenKeys {
  final logInButton = const Key("LoginButton");
  final signUpButton = const Key("SignUpButton");
}

class LoginPage {
  final loginTitle = const Key("LoginTitle");
  final showPasswordButton = const Key("ShowPasswordButton");
  final forgotPasswordButton = const Key("ForgotPasswordButton");
  final continueButton = const Key("ContinueButton");
  final backButton = const Key("BackButton");
  final emailTab = const Key("EmailTab");
  final mobileNumberTextField = const Key("MobileNumberTextField");
  final passwordTextFieldForMobileTab =
      const Key("PasswordTextFieldForMobileTab");
  final mobileNumberPrefixDropdown = const Key("MobileNumberPrefixDropdown");
  final mobileNumberPrefixSearchField =
      const Key("mobileNumberPrefixSearchField");
  final otpConfirmButton = const Key("OtpConfirmationButton");
}

class CardActions {
  final freezeCardButton = const Key("FreezeCardButton");
  final unFreezeCardButton = const Key("UnFreezeCardButton");
}

class NavigationKeys {
  final bottomNavBar = const Key("BottomNavBar");
}

class CardsPage {
  final cardsPageTitle = const Key("cardsPageTitle");
}

class Keys {
  final welcomeScreen = WelcomeScreenKeys();
  final loginPage = LoginPage();
  final navigation = NavigationKeys();
  final cardsPage = CardsPage();
  final cardActions = CardActions();
}

final keys = Keys();
