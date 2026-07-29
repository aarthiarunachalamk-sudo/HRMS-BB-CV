import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/splash_screen.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';

void main() {
  testWidgets('starts on the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
