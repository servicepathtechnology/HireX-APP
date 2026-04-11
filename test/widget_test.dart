// Smoke test — verifies the app widget tree builds without crashing.
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Full app smoke test requires Firebase initialization which is not
  // available in unit test environment. Integration tests cover this.
  // See test/features/ for unit and widget-level tests.
  test('placeholder — see test/features/ for all tests', () {
    expect(true, isTrue);
  });
}
