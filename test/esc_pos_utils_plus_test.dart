import 'package:esc_pos_utils_plus_forked/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is capabilities.isEmpty is completed', () {
    expect(printCapabilities.isEmpty, true);
  });
  test('is capabilities.isNotEmpty is completed', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await CapabilityProfile.ensureProfileLoaded();
    CapabilityProfile.load();
    print("capabilities.length ${printCapabilities.length}");
    expect(printCapabilities.isNotEmpty, true);
  });
}
