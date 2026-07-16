import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'admin_palette.dart';
import 'admin_service.dart';
import 'admin_widgets.dart';
import 'admin_success_screen.dart';

class AdminAddEmployeeScreen extends StatefulWidget {
  const AdminAddEmployeeScreen({super.key});

  @override
  State<AdminAddEmployeeScreen> createState() => _AdminAddEmployeeScreenState();
}

class _AdminAddEmployeeScreenState extends State<AdminAddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  String _selectedDept = 'HR';
  String _selectedRole = 'Employee';
  bool _saving = false;

  static const _depts = ['HR', 'Finance', 'IT', 'Marketing', 'Operations', 'Sales'];
  static const _roles = ['Employee', 'Team Lead', 'Manager', 'HR', 'Finance'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() => _saving = true);
    final response = await AdminService().createEmployee({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'designation': _designationCtrl.text.trim(),
      'department': _selectedDept,
      'role': _selectedRole,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (response['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response['message'] ?? 'Employee creation failed.'}')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSuccessScreen(
          message: 'Employee Created\nSuccessfully!',
          subMessage:
              'Temporary credentials created for ${_emailCtrl.text.trim().isEmpty ? 'employee email' : _emailCtrl.text.trim()}',
          actionLabel: 'View Employees',
          onAction: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AdminPalette.of(context);
    return AdminShell(
      title: 'Add Employee',
      child: Form(
        key: _formKey,
        child: adminPageList([
          AdminCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: c.primary.withOpacity(0.14),
                  child: Icon(Icons.person_add_rounded, color: c.primary, size: 30),
                ),
                const SizedBox(height: 10),
                adminTitle('+ Add Employee', 15, c),
              ],
            ),
          ),
          const SizedBox(height: 4),

          _buildField(c, 'Full Name', _nameCtrl, Icons.person_outline_rounded,
              hint: 'Enter full name'),
          _autoIdNote(c),
          _buildField(c, 'Email Address', _emailCtrl, Icons.mail_outline_rounded,
              hint: 'employee@company.com', inputType: TextInputType.emailAddress),
          _buildField(c, 'Phone Number', _phoneCtrl, Icons.phone_outlined,
              hint: '+91 XXXXX XXXXX', inputType: TextInputType.phone),
          _buildField(c, 'Designation', _designationCtrl, Icons.work_outline_rounded,
              hint: 'e.g. HR Executive'),

          // Department dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminMuted('Department', 12, c),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: AppDropdownButton<String>(
                    value: _selectedDept,
                    isExpanded: true,
                    dropdownColor: c.surface,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 14),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.primary),
                    items: _depts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDept = v!),
                  ),
                ),
              ),
            ]),
          ),

          // Role dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              adminMuted('Role', 12, c),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: c.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: AppDropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    dropdownColor: c.surface,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600, fontSize: 14),
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: c.primary),
                    items: _roles
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedRole = v!),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 8),
          AdminPrimaryButton(
            label: _saving ? 'Saving...' : 'Save Employee',
            onTap: _submit,
            icon: Icons.save_rounded,
          ),
        ]),
      ),
    );
  }

  Widget _buildField(
    AdminPalette c,
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String hint = '',
    TextInputType inputType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        adminMuted(label, 12, c),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: inputType,
          style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.hint, fontSize: 13),
            prefixIcon: Icon(icon, color: c.muted, size: 20),
            filled: true,
            fillColor: c.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.primary, width: 2),
            ),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ]),
    );
  }

  Widget _autoIdNote(AdminPalette c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(Icons.badge_rounded, color: c.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Employee ID will be generated automatically',
                style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
