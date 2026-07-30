import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';

void main() {
  testWidgets('submission popup displays live upload status', (tester) async {
    final status = ValueNotifier('Connecting securely to the HRMS server...');
    addTearDown(status.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppSubmissionProgressDialog(status: status)),
      ),
    );

    expect(find.text('Submitting Registration'), findsOneWidget);
    expect(
      find.text('Connecting securely to the HRMS server...'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    status.value = 'Uploading 8 documents securely...';
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Uploading 8 documents securely...'), findsOneWidget);
    expect(find.textContaining('Automatic retry is enabled'), findsOneWidget);
  });
}
