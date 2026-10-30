import 'package:flutter_test/flutter_test.dart';
import 'package:dooja/screens/auth.dart';
void main() { test('phone', () {
  for (final x in ['07700000001','077000000001','7700000001','+964 770 000 0001','9647700000001','0 770 000 0001','00964 7700000001']) { expect(normPhone(x), '07700000001', reason: x); }
  expect(normPhone('07700000002'), '07700000002'); expect(normPhone('123'), null);
});}
