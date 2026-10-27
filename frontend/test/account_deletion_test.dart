import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Account/account_settings_screen.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Account/delete_account_screen.dart';

void main() {
  testWidgets('DeleteAccountScreen displays required Google Play compliance text and manages checkbox state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: DeleteAccountScreen(
          userId: 'BBEMP00001',
          initialRequest: null,
          checkStatusOnInit: false,
        ),
      ),
    );
    await tester.pump();

    // Verify Title
    expect(find.text('Delete Account'), findsOneWidget);

    // Verify Compliance Warning text
    expect(
      find.textContaining('Deleting your account will remove your HRMS account and eligible associated personal data.'),
      findsOneWidget,
    );

    // Verify Data that may be deleted section
    expect(find.text('Data that may be deleted'), findsOneWidget);
    expect(find.text('User profile information'), findsOneWidget);
    expect(find.text('Profile photo'), findsOneWidget);

    // Verify Data that may be retained section
    expect(find.text('Data that may be retained if required'), findsOneWidget);
    expect(find.text('Attendance records'), findsOneWidget);
    expect(find.text('Payroll records'), findsOneWidget);

    // Verify Retained records explanation
    expect(
      find.textContaining('Retained records will no longer be used for normal app access after account deletion.'),
      findsOneWidget,
    );

    // Verify Confirmation checkbox text
    final checkboxTextFinder = find.text(
      'I understand that requesting account deletion may permanently remove my account and eligible associated data.',
    );
    expect(checkboxTextFinder, findsOneWidget);

    // Verify Primary Action button is disabled initially
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Request Account Deletion');
    expect(buttonFinder, findsOneWidget);
    ElevatedButton button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNull);

    // Tap Checkbox to select it
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await tester.pump();

    // Verify Primary Action button is now enabled
    button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.onPressed, isNotNull);

    // Tap Request Account Deletion and verify Confirmation Dialog
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Confirm Account Deletion'), findsOneWidget);
    expect(
      find.text('Are you sure you want to request deletion of your account?'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm Deletion'), findsOneWidget);

    // Tap Cancel to dismiss dialog cleanly
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm Account Deletion'), findsNothing);
  });

  testWidgets('AccountSettingsScreen displays overview, Change Password and Delete Account options', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccountSettingsScreen(
          userId: 'BBEMP00001',
          email: 'test@bitbytetech.org',
          role: 'Employee',
          loadOnInit: false,
        ),
      ),
    );
    // Let async loads finish
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify title and user info
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('ID: BBEMP00001'), findsOneWidget);

    // Verify Change Password
    expect(find.text('Change Password'), findsOneWidget);

    // Verify Delete Account option
    expect(find.text('Delete Account'), findsOneWidget);
    expect(
      find.text('Request permanent deletion of your account and eligible data'),
      findsOneWidget,
    );
  });
}
