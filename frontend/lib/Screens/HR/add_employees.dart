import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';

class AddEmployeePage extends StatefulWidget {
  final Map<String, dynamic> employee;
  const AddEmployeePage({super.key, required this.employee});

  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  bool _isLoading = false;
  static const Color _green = Color(0xFF43E97B);

  final _emailCtrl = TextEditingController();
  final _reportingTLCtrl = TextEditingController();
  final _workLocationCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String _department = 'hr';
  String _designation = 'associate';
  String _employmentType = 'full_time';

  final List<Map<String, String>> _departments = [
    {'value': 'hr', 'label': 'HR'},
    {'value': 'marketing', 'label': 'Marketing'},
    {'value': 'digital_marketing', 'label': 'Digital Marketing'},
    {'value': 'webapp', 'label': 'WebApp'},
    {'value': 'mobile_app', 'label': 'Mobile App'},
    {'value': 'sales', 'label': 'Sales'},
  ];

  final List<Map<String, String>> _designations = [
    {'value': 'associate', 'label': 'Associate'},
    {'value': 'intern', 'label': 'Intern'},
    {'value': 'tl', 'label': 'TL'},
    {'value': 'ceo', 'label': 'CEO'},
    {'value': 'md', 'label': 'MD'},
  ];

  final List<Map<String, String>> _employmentTypes = [
    {'value': 'full_time', 'label': 'Full Time'},
    {'value': 'part_time', 'label': 'Part Time'},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _reportingTLCtrl.dispose();
    _workLocationCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: ThemeConfig.blueAccent)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty || _dobCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.redAccent));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.54:8000/api/add-employee/${widget.employee['id']}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employee_email': _emailCtrl.text.trim(),
          'department': _department,
          'designation': _designation,
          'date_of_joining': _dobCtrl.text.trim(),
          'employment_type': _employmentType,
          'reporting_tl': _reportingTLCtrl.text.trim(),
          'work_location': _workLocationCtrl.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: ThemeConfig.getCardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF43E97B), size: 28),
              const SizedBox(width: 12),
              Text('Employee Added!', style: TextStyle(color: ThemeConfig.getTextPrimary(context), fontWeight: FontWeight.bold)),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Employee credentials sent to email!', style: TextStyle(color: ThemeConfig.getTextSecondary(context))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF43E97B).withAlpha(20), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF43E97B))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Employee ID: ${data['employee_id']}', style: const TextStyle(color: Color(0xFF43E97B), fontWeight: FontWeight.bold)),
                  Text('OTC: ${data['otc']}', style: const TextStyle(color: Color(0xFF4FACFE), fontWeight: FontWeight.bold)),
                ]),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done', style: TextStyle(color: Color(0xFF4FACFE), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${data['message']}'), backgroundColor: Colors.redAccent));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeConfig.isDark(context);
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final emp = widget.employee;

    return Scaffold(
      body: ConstellationBackground(
        accentColor: _green,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Add Employee', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${emp['first_name']} ${emp['last_name']}', style: TextStyle(color: textSecondary, fontSize: 11)),
                  ])),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Employee Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_green, Color(0xFF38F9D7)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(
                            '${emp['first_name']?[0] ?? '?'}${emp['last_name']?[0] ?? ''}',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${emp['first_name']} ${emp['last_name']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          Text(emp['personal_email'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(emp['mobile'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Employment Details
                    Text('Employment Details', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _card(cardBg, cardBorder, [
                      _label('Employee Email *', textSecondary),
                      _field(_emailCtrl, isDark, textPrimary, cardBorder, keyboard: TextInputType.emailAddress, hint: 'employee@bitbyte.com'),
                      const SizedBox(height: 14),
                      _label('Department *', textSecondary),
                      _dropdown(_department, _departments, (v) => setState(() => _department = v!), isDark, textPrimary, cardBg, cardBorder),
                      const SizedBox(height: 14),
                      _label('Designation *', textSecondary),
                      _dropdown(_designation, _designations, (v) => setState(() => _designation = v!), isDark, textPrimary, cardBg, cardBorder),
                      const SizedBox(height: 14),
                      _label('Date of Joining *', textSecondary),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_month_outlined, color: Color(0xFF4FACFE), size: 18),
                            const SizedBox(width: 10),
                            Text(_dobCtrl.text.isEmpty ? 'Select Date' : _dobCtrl.text, style: TextStyle(color: _dobCtrl.text.isEmpty ? Colors.grey : textPrimary, fontSize: 13)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('Employment Type *', textSecondary),
                      _dropdown(_employmentType, _employmentTypes, (v) => setState(() => _employmentType = v!), isDark, textPrimary, cardBg, cardBorder),
                      const SizedBox(height: 14),
                      _label('Reporting TL', textSecondary),
                      _field(_reportingTLCtrl, isDark, textPrimary, cardBorder, hint: 'TL Name'),
                      const SizedBox(height: 14),
                      _label('Work Location', textSecondary),
                      _field(_workLocationCtrl, isDark, textPrimary, cardBorder, hint: 'Chennai Office'),
                    ]),
                    const SizedBox(height: 20),

                    // OTC Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FACFE).withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4FACFE).withAlpha(80)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF4FACFE), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'An OTC (One Time Credential) will be auto-generated and sent to the employee email for first login.',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    GestureDetector(
                      onTap: _isLoading ? null : _submit,
                      child: Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(gradient: ThemeConfig.blueGradient, borderRadius: BorderRadius.circular(14)),
                        child: Center(child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Add Employee & Send Credentials', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Color bg, Color border, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _label(String t, Color ts) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _field(TextEditingController ctrl, bool isDark, Color tp, Color cb, {TextInputType keyboard = TextInputType.text, String hint = ''}) {
    return TextFormField(
      controller: ctrl, keyboardType: keyboard,
      style: TextStyle(color: tp, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5)),
      ),
    );
  }

  Widget _dropdown(String value, List<Map<String, String>> items, ValueChanged<String?> onChanged, bool isDark, Color tp, Color cardBg, Color cb) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cb),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true,
          dropdownColor: cardBg,
          style: TextStyle(color: tp, fontSize: 13),
          items: items.map((i) => DropdownMenuItem(value: i['value'], child: Text(i['label']!))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}