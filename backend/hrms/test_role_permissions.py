from django.test import SimpleTestCase

from .role_permissions import has_permission, permissions_for_role


class RolePermissionPolicyTests(SimpleTestCase):
    def test_employee_can_view_own_payroll_but_cannot_publish(self):
        self.assertTrue(has_permission('employee', 'payroll', 'view'))
        self.assertFalse(has_permission('employee', 'payroll', 'publish'))

    def test_tl_can_approve_team_leave_but_cannot_access_payroll(self):
        self.assertTrue(has_permission('tl', 'leave', 'approve'))
        self.assertFalse(has_permission('tl', 'payroll', 'view'))

    def test_hr_can_publish_and_ceo_can_approve_payroll(self):
        self.assertTrue(has_permission('hr', 'payroll', 'publish'))
        self.assertTrue(has_permission('ceo', 'payroll', 'approve'))

    def test_finance_can_approve_but_not_publish_payroll(self):
        self.assertTrue(has_permission('finance', 'payroll', 'approve'))
        self.assertFalse(has_permission('finance', 'payroll', 'publish'))

    def test_superadmin_has_every_declared_action(self):
        for action in ('view', 'create', 'edit', 'approve', 'publish', 'administer'):
            self.assertTrue(has_permission('superadmin', 'payroll', action))

    def test_unknown_role_has_no_permissions(self):
        self.assertEqual(permissions_for_role('unknown'), {})
