import 'package:carelink_app/features/elder/screens/active_video_call_screen.dart';
import 'package:carelink_app/features/elder/screens/kamala_ready_screen.dart';
import 'package:carelink_app/features/elder/screens/student_checkin_complete_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const elderName = 'Leela Perera';
  final scheduledAt = DateTime(2026, 10, 7, 17, 30);

  Future<void> pumpCallFlow(
    WidgetTester tester, {
    required String callType,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    void openCall(BuildContext context, String type) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ActiveVideoCallScreen(
            elderId: 'elder-42',
            elderName: elderName,
            elderImageUrl: null,
            companionId: 'student-17',
            connectionId: 'connection-9',
            checkInId: 'checkin-23',
            scheduledAt: scheduledAt,
            durationMinutes: 40,
            callType: type,
            onEndCall: () async {
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => StudentCheckInCompleteScreen(
                    elderId: 'elder-42',
                    elderName: elderName,
                    elderImageUrl: null,
                    companionId: 'student-17',
                    connectionId: 'connection-9',
                    checkInId: 'checkin-23',
                    scheduledAt: scheduledAt,
                    durationMinutes: 40,
                    callType: type,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-ready'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KamalaReadyScreen(
                      elderId: 'elder-42',
                      elderName: elderName,
                      elderImageUrl: null,
                      scheduledAt: scheduledAt,
                      durationMinutes: 40,
                      mode: callType,
                      companionId: 'student-17',
                      connectionId: 'connection-9',
                      checkInId: 'checkin-23',
                      onStartCall: () => openCall(context, 'Video'),
                      onVoiceCall: () => openCall(context, 'Voice'),
                      onMessageInstead: () {},
                    ),
                  ),
                ),
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-ready')));
    await tester.pumpAndSettle();
  }

  testWidgets('video call completes and returns to Student Home', (
    tester,
  ) async {
    await pumpCallFlow(tester, callType: 'Video');

    expect(find.text('$elderName is ready'), findsOneWidget);
    expect(find.text('Older Adult'), findsOneWidget);
    expect(find.textContaining('Video check-in'), findsOneWidget);
    expect(find.text('40 min'), findsOneWidget);

    await tester.tap(find.text('Start video call'));
    await tester.pumpAndSettle();
    expect(find.byType(ActiveVideoCallScreen), findsOneWidget);
    expect(find.text(elderName), findsOneWidget);
    expect(find.textContaining('VIDEO'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('End video call'), findsOneWidget);
    expect(find.text('LP'), findsWidgets);

    await tester.tap(find.text('End video call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End call').last);
    await tester.pumpAndSettle();

    expect(find.byType(StudentCheckInCompleteScreen), findsOneWidget);
    expect(find.text('Check-in complete'), findsOneWidget);
    expect(find.text(elderName), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('40 min'), findsOneWidget);

    await tester.tap(find.text('Back to home'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice-only uses the same call and completion flow', (
    tester,
  ) async {
    await pumpCallFlow(tester, callType: 'Voice');

    await tester.tap(find.text('Voice only'));
    await tester.pumpAndSettle();
    expect(find.byType(ActiveVideoCallScreen), findsOneWidget);
    expect(find.textContaining('CONNECTED'), findsWidgets);
    expect(find.text('Camera'), findsNothing);
    expect(find.text('End voice call'), findsOneWidget);

    await tester.tap(find.text('End voice call'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End call').last);
    await tester.pumpAndSettle();
    expect(find.byType(StudentCheckInCompleteScreen), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
