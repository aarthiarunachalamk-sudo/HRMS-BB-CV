import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/performance_score_breakdown.dart';

void main() {
  testWidgets('shows weighted performance calculation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PerformanceScoreBreakdown(
            breakdown: {
              'task_completion': {
                'score': 75,
                'weight': .40,
                'contribution': 30,
              },
            },
          ),
        ),
      ),
    );

    expect(find.text('Task Completion: 75.00 × 40% = 30.00'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('handles not enough data', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PerformanceScoreBreakdown(breakdown: {})),
      ),
    );
    expect(find.text('No score breakdown is available.'), findsOneWidget);
  });
}
