import 'dart:io';

/// Helper to detect if tests are running in CI environment
class CIDetection {
  /// Returns true if running in a CI environment
  /// Checks common CI environment variables
  static bool get isCI {
    // Check common CI environment variables
    final ciEnvVars = [
      'CI',
      'CONTINUOUS_INTEGRATION',
      'BUILD_NUMBER',
      'GITHUB_ACTIONS',
      'GITLAB_CI',
      'CIRCLECI',
      'TRAVIS',
      'JENKINS_URL',
      'BITBUCKET_BUILD_NUMBER',
      'TEAMCITY_VERSION',
    ];

    return ciEnvVars.any(
      (envVar) =>
          Platform.environment.containsKey(envVar) &&
          Platform.environment[envVar]?.toLowerCase() != 'false',
    );
  }

  /// Returns the name of the CI platform if detected, null otherwise
  static String? get ciPlatform {
    if (Platform.environment.containsKey('GITHUB_ACTIONS')) {
      return 'GitHub Actions';
    }
    if (Platform.environment.containsKey('GITLAB_CI')) {
      return 'GitLab CI';
    }
    if (Platform.environment.containsKey('CIRCLECI')) {
      return 'CircleCI';
    }
    if (Platform.environment.containsKey('TRAVIS')) {
      return 'Travis CI';
    }
    if (Platform.environment.containsKey('JENKINS_URL')) {
      return 'Jenkins';
    }
    if (Platform.environment.containsKey('BITBUCKET_BUILD_NUMBER')) {
      return 'Bitbucket Pipelines';
    }
    if (Platform.environment.containsKey('TEAMCITY_VERSION')) {
      return 'TeamCity';
    }
    if (Platform.environment.containsKey('CI')) {
      return 'CI (Generic)';
    }
    return null;
  }
}
