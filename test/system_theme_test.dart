import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:system_theme/system_theme.dart';

void main() {
  const MethodChannel channel = MethodChannel('system_theme');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    test('Get accent color', () async {
      final color = await channel.invokeMethod(kGetSystemAccentColorMethod);
      expect(kDefaultFallbackColor.toString(), color);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
