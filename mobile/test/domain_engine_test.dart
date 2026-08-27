import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/feedback_catalog.dart';
import 'package:right_posture/domain/joint_angle.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/rep_evaluator.dart';
import 'package:right_posture/domain/session_summary.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';

final thresholds = ExerciseThresholds(
  joints: {
    'knee': JointThreshold(minimum: 70, maximum: 140, deviationThreshold: 10),
  },
);

void main() {
  group('jointAngle', () {
    test('calculates right and straight angles', () {
      expect(
        jointAngle(const Point2(0, 1), const Point2(0, 0), const Point2(1, 0)),
        closeTo(90, 1e-9),
      );
      expect(
        jointAngle(const Point2(-1, 0), const Point2(0, 0), const Point2(1, 0)),
        closeTo(180, 1e-9),
      );
    });

    test('rejects degenerate and non-finite points', () {
      expect(
        jointAngle(const Point2(0, 0), const Point2(0, 0), const Point2(1, 0)),
        isNull,
      );
      expect(
        jointAngle(
          const Point2(double.nan, 0),
          const Point2(0, 0),
          const Point2(1, 0),
        ),
        isNull,
      );
    });
  });

  group('SquatRepDetector', () {
    test('counts standing-bottom-standing once', () {
      final detector = SquatRepDetector();
      expect(
        [170.0, 100.0, 170.0]
            .map((angle) => detector.addKneeAngle(angle, confidenceOk: true))
            .whereType<SquatRepCompletion>(),
        hasLength(1),
      );
    });

    test('does not count standing jitter', () {
      final detector = SquatRepDetector();
      final results = [170.0, 158.0, 155.0, 160.0, 170.0]
          .map((angle) => detector.addKneeAngle(angle, confidenceOk: true))
          .whereType<SquatRepCompletion>();
      expect(results, isEmpty);
      expect(detector.incompleteAttemptCount, 1);
    });

    test('completes deliberate shallow attempt with extrema', () {
      final detector = SquatRepDetector();
      SquatRepCompletion? completion;
      for (final angle in [170.0, 150.0, 145.0, 165.0]) {
        completion =
            detector.addKneeAngle(angle, confidenceOk: true) ?? completion;
      }

      expect(completion, isNotNull);
      expect(completion!.startAngle, 170);
      expect(completion.minimumAngle, 145);
      expect(completion.excursion, 25);
    });

    test('abandoned attempt stays separate from completed reps', () {
      final detector = SquatRepDetector();
      final results = [170.0, 150.0, 140.0]
          .map((angle) => detector.addKneeAngle(angle, confidenceOk: true))
          .whereType<SquatRepCompletion>();

      expect(results, isEmpty);
      expect(detector.incompleteAttemptCount, 0);
      detector.reset();
      expect(detector.phase, SquatMovementPhase.waitingForStanding);
      expect(detector.incompleteAttemptCount, 0);
    });

    test('requires initial standing and ignores low confidence', () {
      final detector = SquatRepDetector();
      expect(detector.addKneeAngle(100, confidenceOk: true), isNull);
      expect(detector.addKneeAngle(170, confidenceOk: true), isNull);
      expect(detector.addKneeAngle(100, confidenceOk: false), isNull);
      expect(detector.addKneeAngle(170, confidenceOk: true), isNull);
    });

    test('returns the minimum angle reached at the bottom', () {
      final detector = SquatRepDetector();
      for (final angle in [170.0, 105.0, 90.0]) {
        expect(detector.addKneeAngle(angle, confidenceOk: true), isNull);
      }
      final completion = detector.addKneeAngle(170, confidenceOk: true);
      expect(completion!.minimumAngle, 90);
      expect(completion.excursion, 80);
    });

    test('provides phase-aware coaching', () {
      final detector = SquatRepDetector();
      expect(detector.coachingFor(140), SquatCoaching.standTall);
      detector.addKneeAngle(170, confidenceOk: true);
      expect(detector.coachingFor(170), SquatCoaching.ready);
      detector.addKneeAngle(130, confidenceOk: true);
      expect(detector.coachingFor(130), SquatCoaching.goLower);
      detector.addKneeAngle(100, confidenceOk: true);
      expect(detector.coachingFor(100), SquatCoaching.depthGood);
      expect(detector.coachingFor(120), SquatCoaching.standUp);
      expect(detector.coachingFor(60), SquatCoaching.tooDeep);
      detector.addKneeAngle(170, confidenceOk: true);
      expect(detector.coachingFor(170), SquatCoaching.ready);
    });
  });

  group('RepEvaluator', () {
    test('uses median baseline and marks first three reps calibrating', () {
      final evaluator = RepEvaluator(thresholds);
      final reps = [100.0, 130.0, 110.0]
          .map(
            (angle) => evaluator.evaluate({'knee': angle}, confidenceOk: true)!,
          )
          .toList();
      expect(
        reps.map((rep) => rep.status),
        everyElement(RepStatus.calibrating),
      );
      expect(evaluator.baseline!['knee'], 110);
    });

    test('moves warning to degraded after persistent deviation', () {
      final evaluator = calibratedEvaluator();
      final warning = evaluator.evaluate({'knee': 125}, confidenceOk: true)!;
      final degraded = evaluator.evaluate({'knee': 126}, confidenceOk: true)!;
      expect(warning.status, RepStatus.warning);
      expect(degraded.status, RepStatus.degraded);
      expect(degraded.issues.single.metric, MovementMetric.kneeAngle);
      expect(feedbackForRep(degraded), isNotEmpty);
    });

    test('good rep resets persistence', () {
      final evaluator = calibratedEvaluator();
      expect(
        evaluator.evaluate({'knee': 125}, confidenceOk: true)!.status,
        RepStatus.warning,
      );
      expect(
        evaluator.evaluate({'knee': 108}, confidenceOk: true)!.status,
        RepStatus.good,
      );
      expect(
        evaluator.evaluate({'knee': 126}, confidenceOk: true)!.status,
        RepStatus.warning,
      );
    });

    test('directional feedback explains depth correction', () {
      final evaluator = calibratedEvaluator();
      expect(
        feedbackForRep(evaluator.evaluate({'knee': 125}, confidenceOk: true)!),
        'Next rep: go slightly lower',
      );
      evaluator.evaluate({'knee': 110}, confidenceOk: true);
      expect(
        feedbackForRep(evaluator.evaluate({'knee': 95}, confidenceOk: true)!),
        'Next rep: do not go as deep',
      );
    });

    test(
      'absolute failure degrades immediately and bad confidence is ignored',
      () {
        final evaluator = calibratedEvaluator();
        expect(evaluator.evaluate({'knee': 20}, confidenceOk: false), isNull);
        final rep = evaluator.evaluate({'knee': 60}, confidenceOk: true)!;
        expect(rep.number, 4);
        expect(rep.status, RepStatus.degraded);
        expect(rep.issues.single.metric, MovementMetric.kneeAngle);
        expect(feedbackForRep(rep), 'Next rep: do not go as deep');
      },
    );

    test('non-finite and incomplete samples are ignored', () {
      final evaluator = RepEvaluator(thresholds);
      expect(
        evaluator.evaluate({'knee': double.nan}, confidenceOk: true),
        isNull,
      );
      expect(
        evaluator.evaluate({'knee': double.infinity}, confidenceOk: true),
        isNull,
      );
      expect(evaluator.evaluate(const {}, confidenceOk: true), isNull);
      expect(evaluator.evaluate({'knee': 100}, confidenceOk: true)!.number, 1);
    });
  });

  test('summary excludes calibration and reports degradation', () {
    final evaluator = calibratedEvaluator();
    final reps = <Rep>[
      ...[100.0, 110.0, 120.0].map(
        (angle) => Rep(
          number: [100.0, 110.0, 120.0].indexOf(angle) + 1,
          angles: {'knee': angle},
          status: RepStatus.calibrating,
        ),
      ),
      evaluator.evaluate({'knee': 110}, confidenceOk: true)!,
      evaluator.evaluate({'knee': 125}, confidenceOk: true)!,
      evaluator.evaluate({'knee': 126}, confidenceOk: true)!,
    ];
    final summary = summarizeSession(reps);
    expect(summary.totalReps, 6);
    expect(summary.formScorePercent, closeTo(100 / 3, 1e-9));
    expect(summary.degradationStartRep, 6);
    expect(summary.primaryResponsibleJoint, 'Knee range');
  });

  test('empty and calibration-only summaries have no score', () {
    expect(summarizeSession(const []).formScorePercent, isNull);
    expect(
      summarizeSession([
        Rep(number: 1, angles: {'knee': 100}, status: RepStatus.calibrating),
      ]).formScorePercent,
      isNull,
    );
  });
}

RepEvaluator calibratedEvaluator() {
  final evaluator = RepEvaluator(thresholds);
  for (final angle in [100.0, 110.0, 120.0]) {
    evaluator.evaluate({'knee': angle}, confidenceOk: true);
  }
  return evaluator;
}
