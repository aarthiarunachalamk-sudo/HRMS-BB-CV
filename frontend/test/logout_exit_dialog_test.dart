import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/logout_exit_dialog.dart';

void main() {
  testWidgets('exit dialog only logs out after explicit confirmation', (
    tester,
  ) async {
    var loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showLogoutExitConfirmation(
                context: context,
                onLogout: () => loggedOut = true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Log Out & Exit?'), findsOneWidget);
    expect(find.text('Stay Logged In'), findsOneWidget);
    expect(loggedOut, isFalse);

    await tester.tap(find.text('Stay Logged In'));
    await tester.pumpAndSettle();

    expect(find.text('Log Out & Exit?'), findsNothing);
    expect(loggedOut, isFalse);
  });

  testWidgets('regular logout asks for confirmation', (tester) async {
    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLogoutConfirmation(
              context: context,
              onLogout: () => loggedOut = true,
            ),
            child: const Text('Logout'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    expect(loggedOut, isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(loggedOut, isFalse);
  });
}
