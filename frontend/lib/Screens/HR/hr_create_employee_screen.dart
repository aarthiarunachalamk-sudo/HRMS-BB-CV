import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'hr_shared.dart';

class HrCreateEmployeeScreen extends StatefulWidget {
  const HrCreateEmployeeScreen({super.key});

  @override
  State<HrCreateEmployeeScreen> createState() => _HrCreateEmployeeScreenState();
}

class _HrCreateEmployeeScreenState extends State<HrCreateEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _doorNo = TextEditingController();
  final _street = TextEditingController();
  final _pincode = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _occupation = TextEditingController();
  final _pan = TextEditingController();
  final _aadhar = TextEditingController();
  String _gender = 'male';
  bool _loading = false;

  @override
  void dispose() {
    for (final controller in [_firstName, _lastName, _email, _phone, _dob, _password, _confirmPassword, _doorNo, _street, _pincode, _city, _state, _occupation, _pan, _aadhar]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await http.post(
        ApiConfig.uri('/create-user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'email': _email.text.trim(),
          'country_code': '+91',
          'phone': _phone.text.trim(),
          'gender': _gender,
          'dob': _dob.text.trim(),
          'password': _password.text,
          'confirm_password': _confirmPassword.text,
          'door_no': _doorNo.text.trim(),
          'street': _street.text.trim(),
          'pincode': _pincode.text.trim(),
          'city': _city.text.trim(),
          'state': _state.text.trim(),
          'occupation': _occupation.text.trim(),
          'pan': _pan.text.trim(),
          'aadhar': _aadhar.text.trim(),
          'role': 'employee',
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['success'] == true ? '${data['message']} ID: ${data['user_id']}' : '${data['message'] ?? data['errors'] ?? 'Employee creation failed'}'),
          backgroundColor: data['success'] == true ? Colors.green : Colors.redAccent,
        ),
      );
      if (data['success'] == true) _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = HrPalette.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        children: [
          HrCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Field(label: 'First Name', controller: _firstName),
              _Field(label: 'Last Name', controller: _lastName),
              _Field(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress),
              _Field(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone),
              _Field(label: 'DOB', controller: _dob, hint: 'YYYY-MM-DD'),
              AppDropdownButtonFormField<String>(
                value: _gender,
                decoration: _decoration(context, 'Gender'),
                dropdownColor: c.surface,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) => setState(() => _gender = value ?? 'male'),
              ),
              const SizedBox(height: 10),
              _Field(label: 'Password', controller: _password, obscure: true),
              _Field(label: 'Confirm Password', controller: _confirmPassword, obscure: true),
            ]),
          ),
          const SizedBox(height: 12),
          HrCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Field(label: 'Door No', controller: _doorNo),
              _Field(label: 'Street', controller: _street),
              _Field(label: 'Pincode', controller: _pincode, keyboardType: TextInputType.number),
              _Field(label: 'City', controller: _city),
              _Field(label: 'State', controller: _state),
              _Field(label: 'Occupation', controller: _occupation),
              _Field(label: 'PAN', controller: _pan),
              _Field(label: 'Aadhar', controller: _aadhar, keyboardType: TextInputType.number),
            ]),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: c.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
            onPressed: _loading ? null : _create,
            icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Create Employee'),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;

  const _Field({required this.label, required this.controller, this.hint, this.keyboardType, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
        decoration: _decoration(context, label, hint),
      ),
    );
  }
}

InputDecoration _decoration(BuildContext context, String label, [String? hint]) {
  final c = HrPalette.of(context);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: c.row,
    labelStyle: TextStyle(color: c.muted),
    hintStyle: TextStyle(color: c.muted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.primary)),
  );
}
