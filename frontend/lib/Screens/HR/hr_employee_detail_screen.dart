import 'package:flutter/material.dart';

import 'hr_shared.dart';
import 'hr_service.dart';
import 'package:hrms_mobileapp_bitbyte/utils/privacy_utils.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_bar_logo.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/employee_avatar.dart';

class HrEmployeeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> employee;

  const HrEmployeeDetailScreen({super.key, required this.employee});

  @override
  State<HrEmployeeDetailScreen> createState() => _HrEmployeeDetailScreenState();
}

class _HrEmployeeDetailScreenState extends State<HrEmployeeDetailScreen> {
  late Map<String, dynamic> employee = Map<String, dynamic>.from(widget.employee);
  bool _saving = false;

  String _get(String key) => '${employee[key] ?? ''}';

  Future<void> _editEmployee() async {
    final registrationId = int.tryParse(_get('registration_id'));
    if (registrationId == null || _saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This employee record cannot be edited yet.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final loaded = await HrService().fetchEditableEmployee(registrationId);
      if (!mounted) return;
      final source = Map<String, dynamic>.from(loaded['employee'] as Map);
      final changes = await _showEditSheet(source);
      if (changes == null || !mounted) return;
      final saved = await HrService().updateEmployee(registrationId, changes);
      final updated = Map<String, dynamic>.from(saved['employee'] as Map);
      setState(() {
        employee.addAll({
          'name': '${updated['first_name'] ?? ''} ${updated['last_name'] ?? ''}'.trim(),
          'phone': updated['mobile'] ?? employee['phone'],
          'gender': updated['gender'] ?? '',
          'dob': updated['dob'] ?? '',
          'blood_group': updated['blood_group'] ?? '',
          'nationality': updated['nationality'] ?? '',
          'marital_status': updated['marital_status'] ?? '',
          'current_city': updated['current_city'] ?? '',
          'current_state': updated['current_state'] ?? '',
          'qualification': updated['qualification'] ?? '',
          'college': updated['college'] ?? '',
          'year_of_passing': updated['year_of_passing'] ?? '',
          'bank_name': updated['bank_name'] ?? '',
          'account_number': updated['account_number'] ?? '',
          'ifsc_code': updated['ifsc_code'] ?? '',
          'branch_name': updated['branch_name'] ?? '',
          'aadhar': updated['aadhar'] ?? '',
          'pan': updated['pan'] ?? '',
          'doc_passport_photo': updated['doc_passport_photo'] ?? employee['doc_passport_photo'],
        });
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee details updated.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit failed: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Map<String, dynamic>?> _showEditSheet(Map<String, dynamic> source) async {
    const fields = <(String, String)>[
      ('first_name', 'First name'), ('last_name', 'Last name'),
      ('personal_email', 'Personal email'), ('mobile', 'Mobile'),
      ('gender', 'Gender'), ('dob', 'Date of birth'),
      ('blood_group', 'Blood group'), ('marital_status', 'Marital status'),
      ('nationality', 'Nationality'), ('current_city', 'Current city'),
      ('current_state', 'Current state'), ('qualification', 'Qualification'),
      ('college', 'College'), ('year_of_passing', 'Year of passing'),
      ('bank_name', 'Bank name'), ('account_number', 'Account number'),
      ('ifsc_code', 'IFSC code'), ('branch_name', 'Bank branch'),
      ('aadhar', 'Aadhaar'), ('pan', 'PAN'),
    ];
    final controllers = {for (final field in fields) field.$1: TextEditingController(text: '${source[field.$1] ?? ''}')};
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
          child: ListView(
            children: [
              Row(children: [
                const Expanded(child: Text('Edit Employee Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close_rounded)),
              ]),
              ...fields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(controller: controllers[field.$1], decoration: InputDecoration(labelText: field.$2, border: const OutlineInputBorder())),
              )),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, {for (final entry in controllers.entries) entry.key: entry.value.text.trim()}),
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
    for (final controller in controllers.values) controller.dispose();
    return result;
  }

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
        actions: [
          IconButton(
            tooltip: 'Edit employee details',
            onPressed: _saving ? null : _editEmployee,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.edit_rounded, color: c.primary),
          ),
        ],
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
                  EmployeeAvatar(
                    name: name,
                    photoUrl: _get('doc_passport_photo'),
                    radius: 36,
                    backgroundColor: c.primary.withAlpha(30),
                    foregroundColor: c.primary,
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
