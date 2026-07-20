import 'package:flutter/material.dart';

import 'hr_shared.dart';
import 'package:hrms_mobileapp_bitbyte/utils/privacy_utils.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';

class HrEmployeeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const HrEmployeeDetailScreen({super.key, required this.employee});

  String _get(String key) => '${employee[key] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);

    // Support both key styles: 'name'/'role'/'id' (from directory)
    // and 'name'/'subtitle'/'trailing' (from stat lists)
    final name = _get('name').isEmpty ? 'Employee' : _get('name');
    final role = _get('role').isNotEmpty
        ? _get('role')
        : _get('subtitle').split('·').first.trim();
    final dept = _get('department').isNotEmpty
        ? _get('department')
        : (_get('subtitle').contains('·')
              ? _get('subtitle').split('·').last.trim()
              : '');
    final id = _get('id').isNotEmpty ? _get('id') : _get('trailing');
    final status = _get('status').isEmpty ? 'Active' : _get('status');
    final isActive = status == 'Active';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const AppBarLogoTitle(title: 'Employee Details'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: c.border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          // ── Header ─────────────────────────────────────────────
          _card(c, [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: c.primary.withAlpha(30),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$role  ·  $dept',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badge(id, c.primary),
                      const SizedBox(width: 8),
                      _badge(status, isActive ? c.success : c.danger),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // ── Employment Details ──────────────────────────────────
          _sectionLabel('Employment Details', c),
          _card(c, [
            _row('Employee ID', id, c),
            _row('Email', _get('email'), c),
            _row('Phone', maskMobileNumber(_get('phone')), c),
            _row('Designation', role, c),
            _row('Department', dept, c),
            _row('Date of Joining', _get('date_of_joining'), c),
            _row('Employment Type', _get('employment_type'), c),
            _row('Work Mode', _workModeLabel(_get('work_mode')), c),
            _row(
              'Reporting TL',
              _get('reporting_tl').isEmpty
                  ? 'Not Assigned'
                  : _get('reporting_tl'),
              c,
              valueColor: _get('reporting_tl').isEmpty ? c.muted : c.primary,
            ),
            _row(
              'Status',
              status,
              c,
              valueColor: isActive ? c.success : c.danger,
            ),
          ]),
          const SizedBox(height: 14),

          // ── Personal Details ────────────────────────────────────
          _sectionLabel('Personal Details', c),
          _card(c, [
            _row('Gender', _get('gender'), c),
            _row('Date of Birth', _get('dob'), c),
            _row('Blood Group', _get('blood_group'), c),
            _row('Nationality', _get('nationality'), c),
            _row('Marital Status', _get('marital_status'), c),
            if (_get('current_city').isNotEmpty ||
                _get('current_state').isNotEmpty)
              _row(
                'Location',
                [
                  _get('current_city'),
                  _get('current_state'),
                ].where((s) => s.isNotEmpty).join(', '),
                c,
              ),
          ]),

          // ── Education ───────────────────────────────────────────
          if (_get('qualification').isNotEmpty ||
              _get('college').isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionLabel('Education', c),
            _card(c, [
              _row('Qualification', _get('qualification'), c),
              _row('College', _get('college'), c),
              _row('Year of Passing', _get('year_of_passing'), c),
            ]),
          ],

          // ── Bank Details ─────────────────────────────────────────
          if (_get('bank_name').isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionLabel('Bank Details', c),
            _card(c, [
              _row('Bank', _get('bank_name'), c),
              _row('Account No.', _obscure(_get('account_number')), c),
              _row('IFSC Code', _get('ifsc_code'), c),
              _row('Branch', _get('branch_name'), c),
            ]),
          ],

          // ── Identity ─────────────────────────────────────────────
          if (_get('aadhar').isNotEmpty || _get('pan').isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionLabel('Identity', c),
            _card(c, [
              if (_get('aadhar').isNotEmpty)
                _row('Aadhaar', _obscure(_get('aadhar'), visibleEnd: 4), c),
              if (_get('pan').isNotEmpty) _row('PAN', _get('pan'), c),
            ]),
          ],
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String _workModeLabel(String value) {
    const map = {
      'work_from_home': 'Work From Home',
      'hybrid': 'Hybrid',
      'onsite': 'OnSite',
    };
    return map[value] ?? (value.isEmpty ? '-' : value);
  }

  String _obscure(String value, {int visibleEnd = 4}) {
    if (value.length <= visibleEnd) return value;
    return '•' * (value.length - visibleEnd) +
        value.substring(value.length - visibleEnd);
  }

  Widget _sectionLabel(String text, HrPalette c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        color: c.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
      ),
    ),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(100)),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Widget _card(HrPalette c, List<Widget> children) {
    // Remove empty SizedBox.shrink children
    final visible = children
        .where((w) => w is! SizedBox || (w.height ?? 1) > 0)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visible,
      ),
    );
  }

  Widget _row(String label, String value, HrPalette c, {Color? valueColor}) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: c.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? c.text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
