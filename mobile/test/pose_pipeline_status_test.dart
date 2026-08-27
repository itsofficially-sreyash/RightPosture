import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/pose_landmark_mapper.dart';
import 'package:right_posture/pose_pipeline.dart';
import 'package:right_posture/pose_pipeline_status.dart';

void main() {
  testWidgets('renders every app-owned pipeline state', (tester) async {
    var retried = false;

    Future<void> pump(PosePipelineSnapshot snapshot) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosePipelineStatusPanel(
              snapshot: snapshot,
              onRetry: () => retried = true,
              showDiagnostics: false,
            ),
          ),
        ),
      );
    }

    await pump(PosePipelineSnapshot(status: PosePipelineStatus.initializing));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await pump(PosePipelineSnapshot(status: PosePipelineStatus.ready));
    expect(find.textContaining('Pose ready'), findsOneWidget);
    expect(find.textContaining('Frames:'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosePipelineStatusPanel(
            snapshot: PosePipelineSnapshot(
              status: PosePipelineStatus.ready,
              squatCandidate: const SquatFrameSample(
                kneeAngle: 92.4,
                side: 'right',
                confidence: 0.87,
              ),
            ),
            onRetry: () {},
            showDiagnostics: true,
          ),
        ),
      ),
    );
    expect(find.textContaining('Knee: 92.4\u00b0 (right)'), findsOneWidget);
    expect(find.textContaining('Confidence: 87%'), findsOneWidget);

    await pump(PosePipelineSnapshot(status: PosePipelineStatus.noPerson));
    expect(find.textContaining('Step into frame'), findsOneWidget);

    await pump(PosePipelineSnapshot(status: PosePipelineStatus.lowConfidence));
    expect(find.textContaining('Show your full body'), findsOneWidget);

    await pump(
      PosePipelineSnapshot(
        status: PosePipelineStatus.failed,
        error: 'Camera unavailable',
      ),
    );
    expect(find.text('Camera unavailable'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('permission denial explains recovery and opens settings', (
    tester,
  ) async {
    var openedSettings = false;
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosePipelineStatusPanel(
            snapshot: PosePipelineSnapshot(
              status: PosePipelineStatus.failed,
              failureKind: PosePipelineFailureKind.permissionDenied,
            ),
            onRetry: () => retried = true,
            onOpenSettings: () => openedSettings = true,
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Camera permission is required'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('open_app_settings')));
    expect(openedSettings, isTrue);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('permission recovery fits compact screen at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: PosePipelineStatusPanel(
              snapshot: PosePipelineSnapshot(
                status: PosePipelineStatus.failed,
                failureKind: PosePipelineFailureKind.permissionDenied,
              ),
              onRetry: () {},
              onOpenSettings: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Open settings'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  test('classifies camera permission exception codes', () {
    expect(
      cameraFailureKind('CameraAccessDenied'),
      PosePipelineFailureKind.permissionDenied,
    );
    expect(
      cameraFailureKind('CameraAccessDeniedWithoutPrompt'),
      PosePipelineFailureKind.permissionDenied,
    );
    expect(
      cameraFailureKind('CameraAccessRestricted'),
      PosePipelineFailureKind.permissionDenied,
    );
    expect(cameraFailureKind('CameraNotFound'), PosePipelineFailureKind.camera);
  });
}
