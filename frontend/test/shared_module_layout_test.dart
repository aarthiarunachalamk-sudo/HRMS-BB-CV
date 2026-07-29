import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Admin/admin_widgets.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/CEO/ceo_widgets.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Employee/employee_shared.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/hr_shared.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Superadmin/sa_shared.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/TL/tl_shared.dart';

void main() {
  const longTitle =
      'A very long employee approval title that must remain aligned';
  const longSubtitle =
      'A long module description that must not overflow on narrow phones';

  Future<void> pumpNarrow(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('Employee shared row fits a narrow phone', (tester) async {
    await pumpNarrow(
      tester,
      const EmployeeListTile(
        icon: Icons.person,
        title: longTitle,
        subtitle: longSubtitle,
        trailing: 'Very long status',
        color: EmployeeColors.blue,
      ),
    );
  });

  testWidgets('HR shared row fits a narrow phone', (tester) async {
    await pumpNarrow(
      tester,
      const HrListTile(
        icon: Icons.badge,
        title: longTitle,
        subtitle: longSubtitle,
        trailing: '12 pending',
      ),
    );
  });

  testWidgets('TL shared row fits a narrow phone', (tester) async {
    await pumpNarrow(
      tester,
      const TlListTile(
        icon: Icons.groups,
        title: longTitle,
        subtitle: longSubtitle,
        trailing: 'In progress',
      ),
    );
  });

  testWidgets('Admin shared row fits a narrow phone', (tester) async {
    await pumpNarrow(
      tester,
      const AdminListTile(
        icon: Icons.admin_panel_settings,
        titleText: longTitle,
        subtitle: longSubtitle,
      ),
    );
  });

  testWidgets('CEO shared row fits a narrow phone', (tester) async {
    await pumpNarrow(
      tester,
      const CeoListTile(
        icon: Icons.analytics,
        titleText: longTitle,
        subtitle: longSubtitle,
      ),
    );
  });

  testWidgets('Superadmin shared row fits a narrow phone', (tester) async {
    await pumpNarrow(
      tester,
      const SaInfoTile(
        icon: Icons.security,
        title: longTitle,
        subtitle: longSubtitle,
        trailing: 'Restricted',
      ),
    );
  });
}
