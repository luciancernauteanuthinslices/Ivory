import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:solarisdemo/models/auth/device_fingerprint_error_type.dart';
import 'package:solarisdemo/models/device_activity.dart';
import 'package:solarisdemo/models/device_consent.dart';
import 'package:solarisdemo/models/user.dart';
import 'package:solarisdemo/services/api_service.dart';

MethodChannel _platform =
    const MethodChannel('com.thinslices.solarisdemo/native');
const getDeviceFingerprintMethod = 'getDeviceFingerprint';
const getIosDeviceFingerprintMethod = 'getIosDeviceFingerprint';

// Check if running in test/CI environment
const bool kIsPatrolTestEnv =
    bool.fromEnvironment('PATROL_TEST', defaultValue: false);

class DeviceFingerprintService extends ApiService {
  DeviceFingerprintService({super.user});

  Future<DeviceFingerprintServiceResponse> createDeviceConsent({
    User? user,
  }) async {
    if (user != null) {
      this.user = user;
    }

    try {
      CreateDeviceConsentRequest reqBody = CreateDeviceConsentRequest(
        confirmedAt: DateTime.now().toUtc(),
        eventType: DeviceConsentEventType.APPROVED,
      );

      final data = await post(
        'person/device/consent',
        body: reqBody.toJson(),
      );
      return CreateDeviceConsentResponse(consentId: data['id']);
    } catch (e) {
      return DeviceFingerprintServiceErrorResponse(
          errorType: DeviceFingerprintErrorType.unableToCreateActivity);
    }
  }

  Future<DeviceFingerprintServiceResponse> createDeviceActivity({
    User? user,
    required DeviceActivityType activityType,
    required String deviceFingerprint,
  }) async {
    if (user != null) {
      this.user = user;
    }

    try {
      await post(
        'person/device/activity',
        body: CreateDeviceActivityRequest(
          activityType: activityType,
          deviceData: deviceFingerprint,
        ).toJson(),
      );
      return CreateDeviceActivityResponse();
    } catch (e) {
      return DeviceFingerprintServiceErrorResponse(
          errorType: DeviceFingerprintErrorType.unableToCreateActivity);
    }
  }

  Future<String?> getDeviceFingerprint(String? consentId) async {
    if (consentId == null) {
      return null;
    }

    // In test/CI environment, return a mock fingerprint to bypass Seon SDK
    if (kIsPatrolTestEnv) {
      debugPrint('🧪 PATROL_TEST mode: Using mock device fingerprint');
      return 'mock_device_fingerprint_for_ci_testing_${consentId}_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        return _platform.invokeMethod(
          getDeviceFingerprintMethod,
          {'consentId': consentId},
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _platform.invokeMethod(
          getIosDeviceFingerprintMethod,
          {'consentId': consentId},
        );
      }

      return null;
    } catch (e) {
      debugPrint('⚠️  Device fingerprint error: $e');
      // In test mode, return mock even on error
      if (kIsPatrolTestEnv) {
        debugPrint('🧪 Returning mock fingerprint due to error in test mode');
        return 'mock_device_fingerprint_error_fallback_${consentId}';
      }
      return null;
    }
  }
}

abstract class DeviceFingerprintServiceResponse extends Equatable {
  @override
  List<Object> get props => [];
}

class CreateDeviceConsentResponse extends DeviceFingerprintServiceResponse {
  final String consentId;

  CreateDeviceConsentResponse({required this.consentId});

  @override
  List<Object> get props => [consentId];
}

class CreateDeviceActivityResponse extends DeviceFingerprintServiceResponse {}

class DeviceFingerprintServiceErrorResponse
    extends DeviceFingerprintServiceResponse {
  final DeviceFingerprintErrorType errorType;

  DeviceFingerprintServiceErrorResponse({required this.errorType});

  @override
  List<Object> get props => [errorType];
}
