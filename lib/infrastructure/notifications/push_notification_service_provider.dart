import 'package:solarisdemo/infrastructure/notifications/push_notification_service.dart';

class PushNotificationServiceProvider {
  PushNotificationServiceProvider._();

  static final PushNotificationServiceProvider instance =
      PushNotificationServiceProvider._();

  PushNotificationService? _service;

  factory PushNotificationServiceProvider.init(
    PushNotificationService service,
  ) {
    instance._service = service;
    return instance;
  }

  PushNotificationService get service => _service!;

  bool get isInitialized => _service != null;
}
