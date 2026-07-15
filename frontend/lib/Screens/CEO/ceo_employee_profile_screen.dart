import 'package:flutter/material.dart';

import 'ceo_widgets.dart';
import 'package:hrms_mobileapp_bitbyte/utils/privacy_utils.dart';

class CeoEmployeeProfileScreen extends StatelessWidget {
  final Map<String, dynamic> employee;

  const CeoEmployeeProfileScreen({super.key, required this.employee});

  String _get(String key) => '${employee[key] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final name = _get('name').isEmpty ? 'Employee' : _get('name');
    final role = _get('role');
    final dept = _get('department');
    final id = _get('id');
    final status = _get('status').isEmpty ? 'Active' : _get('status');
    final isActive = status == 'Active';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CeoShell(
      title: 'Employee Details',
      child: pageList([
        // ── Header card ──────────────────────────────────────────
        _card(context, [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: CeoColors.cyan.withAlpha(30),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: CeoColors.cyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                title(name, 18),
                const SizedBox(height: 4),
                muted('$role  ·  $dept', 13),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _badge(id, CeoColors.cyan),
                    const SizedBox(width: 8),
                    _badge(
                      status,
                      isActive ? CeoColors.green : Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),

        // ── Employment Details ────────────────────────────────────
        _sectionTitle('Employment Details'),
        _card(context, [
          _row('Employee ID', id),
          _row('Email', _get('email')),
          _row('Phone', maskMobileNumber(_get('phone'))),
          _row('Designation', role),
          _row('Department', dept),
          _row('Date of Joining', _get('date_of_joining')),
          _row('Employment Type', _get('employment_type')),
          _row('Work Mode', _workModeLabel(_get('work_mode'))),
          _row(
            'Reporting TL',
            _get('reporting_tl').isEmpty
                ? 'Not Assigned'
                : _get('reporting_tl'),
          ),
          _row('Status', status),
        ]),

        // ── Personal Details ──────────────────────────────────────
        _sectionTitle('Personal Details'),
        _card(context, [
          _row('Gender', _get('gender')),
          _row('Date of Birth', _get('dob')),
          _row('Blood Group', _get('blood_group')),
          _row('Nationality', _get('nationality')),
          _row('Marital Status', _get('marital_status')),
          if (_get('current_city').isNotEmpty ||
              _get('current_state').isNotEmpty)
            _row(
              'Location',
              '${_get('current_city')}, ${_get('current_state')}'
                  .trim()
                  .replaceAll(RegExp(r'^, |, $'), ''),
            ),
        ]),

        // ── Education ─────────────────────────────────────────────
        if (_get('qualification').isNotEmpty || _get('college').isNotEmpty) ...[
          _sectionTitle('Education'),
          _card(context, [
            if (_get('qualification').isNotEmpty)
              _row('Qualification', _get('qualification')),
            if (_get('college').isNotEmpty) _row('College', _get('college')),
            if (_get('year_of_passing').isNotEmpty)
              _row('Year of Passing', _get('year_of_passing')),
          ]),
        ],

        // ── Bank Details ──────────────────────────────────────────
        if (_get('bank_name').isNotEmpty) ...[
          _sectionTitle('Bank Details'),
          _card(context, [
            _row('Bank', _get('bank_name')),
            _row('Account No.', _obscure(_get('account_number'))),
            _row('IFSC Code', _get('ifsc_code')),
            _row('Branch', _get('branch_name')),
          ]),
        ],

        // ── Identity ──────────────────────────────────────────────
        if (_get('aadhar').isNotEmpty || _get('pan').isNotEmpty) ...[
          _sectionTitle('Identity'),
          _card(context, [
            if (_get('aadhar').isNotEmpty)
              _row('Aadhaar', _obscure(_get('aadhar'), visibleEnd: 4)),
            if (_get('pan').isNotEmpty) _row('PAN', _get('pan')),
          ]),
        ],

        const SizedBox(height: 8),
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _workModeLabel(String value) {
    const map = {
      'work_from_home': 'Work From Home',
      'hybrid': 'Hybrid',
      'onsite': 'OnSite',
    };
    return map[value] ?? (value.isEmpty ? '-' : value);
  }

  /// Masks middle characters: "123456789012" → "••••••••9012"
  String _obscure(String value, {int visibleEnd = 4}) {
    if (value.length <= visibleEnd) return value;
    return '•' * (value.length - visibleEnd) +
        value.substring(value.length - visibleEnd);
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
    child: Text(
      text,
      style: const TextStyle(
        color: CeoColors.cyan,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
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

  Widget _card(BuildContext context, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: CeoColors.muted.withAlpha(40)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _row(String label, String value) {
    if (value.isEmpty || value == '-') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: CeoColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
