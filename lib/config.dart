// lib/config.dart
/// テスト用リセットフラグ
const bool isTestReset = bool.fromEnvironment(
  'TEST_RESET',
  defaultValue: false,
);
