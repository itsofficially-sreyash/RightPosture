import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/angle_smoother.dart';

void main() {
  test('median window rejects one noisy angle', () {
    final smoother = AngleSmoother();

    expect(smoother.add(170), isNull);
    expect(smoother.add(170), isNull);
    expect(smoother.add(170), 170);
    expect(smoother.add(90), 170);
  });

  test('reset prevents values crossing tracking boundaries', () {
    final smoother = AngleSmoother();
    smoother.add(170);
    smoother.add(170);
    smoother.reset();

    expect(smoother.add(100), isNull);
    expect(smoother.add(100), isNull);
    expect(smoother.add(100), 100);
  });
}
