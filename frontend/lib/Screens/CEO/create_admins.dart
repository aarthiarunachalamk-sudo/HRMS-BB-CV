import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';

class CeoCreateAdminsPage extends StatefulWidget {
  const CeoCreateAdminsPage({super.key});

  @override
  State<CeoCreateAdminsPage> createState() => _CeoCreateAdminsPageState();
}

class _CeoCreateAdminsPageState extends State<CeoCreateAdminsPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _doorNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _occupationController = TextEditingController();
  final _panController = TextEditingController();
  final _aadharController = TextEditingController();

  String _selectedCountryCode = '+91';
  String _selectedGender = 'male';
  String _selectedRole = 'hr';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'name': 'India'},
    {'code': '+1', 'name': 'USA'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+61', 'name': 'Australia'},
    {'code': '+971', 'name': 'UAE'},
  ];

  final List<Map<String, String>> _roles = [
    {'value': 'hr', 'label': 'HR'},
    {'value': 'finance', 'label': 'Finance'},
    {'value': 'marketing', 'label': 'Marketing Team'},
    {'value': 'it', 'label': 'IT Team'},
    {'value': 'admin', 'label': 'Admin'},
    {'value': 'manager', 'label': 'Manager'},
    {'value': 'tl', 'label': 'TL'},
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _doorNoController.dispose();
    _streetController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _occupationController.dispose();
    _panController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.56:8000/api/create-user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'country_code': _selectedCountryCode,
          'phone': _phoneController.text.trim(),
          'gender': _selectedGender,
          'dob': _dobController.text.trim(),
          'password': _passwordController.text,
          'confirm_password': _confirmPasswordController.text,
          'door_no': _doorNoController.text.trim(),
          'street': _streetController.text.trim(),
          'pincode': _pincodeController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'occupation': _occupationController.text.trim(),
          'pan': _panController.text.trim(),
          'aadhar': _aadharController.text.trim(),
          'role': _selectedRole,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${data['message']} — ID: ${data['user_id']}'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _firstNameController.clear(); _lastNameController.clear();
        _emailController.clear(); _phoneController.clear();
        _dobController.clear(); _passwordController.clear();
        _confirmPasswordController.clear(); _doorNoController.clear();
        _streetController.clear(); _pincodeController.clear();
        _cityController.clear(); _stateController.clear();
        _occupationController.clear(); _panController.clear();
        _aadharController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${data['message'] ?? 'Error'}'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
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

    return Scaffold(
      body: ConstellationBackground(
        accentColor: ThemeConfig.blueAccent,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Create Team Member', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Role', textPrimary),
                        _card(cardBg, cardBorder, [
                          Text('Select Role', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                isExpanded: true,
                                dropdownColor: isDark ? const Color(0xFF0A121E) : Colors.white,
                                style: TextStyle(color: textPrimary, fontSize: 14),
                                items: _roles.map((r) => DropdownMenuItem(value: r['value'], child: Text(r['label']!))).toList(),
                                onChanged: (val) => setState(() => _selectedRole = val!),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _sectionTitle('Basic Details', textPrimary),
                        _card(cardBg, cardBorder, [
                          Row(children: [
                            Expanded(child: _field('First Name', _firstNameController, isDark, textPrimary, textSecondary, cardBorder)),
                            const SizedBox(width: 10),
                            Expanded(child: _field('Last Name', _lastNameController, isDark, textPrimary, textSecondary, cardBorder)),
                          ]),
                          const SizedBox(height: 14),
                          _field('Email', _emailController, isDark, textPrimary, textSecondary, cardBorder, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCountryCode,
                                  dropdownColor: isDark ? const Color(0xFF0A121E) : Colors.white,
                                  style: TextStyle(color: textPrimary, fontSize: 13),
                                  items: _countryCodes.map((c) => DropdownMenuItem(value: c['code'], child: Text('${c['code']!} ${c['name']!}'))).toList(),
                                  onChanged: (val) => setState(() => _selectedCountryCode = val!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _field('Phone', _phoneController, isDark, textPrimary, textSecondary, cardBorder, keyboardType: TextInputType.phone)),
                          ]),
                          const SizedBox(height: 14),
                          Text('Gender', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: ['male', 'female', 'other'].map((g) => Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedGender = g),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedGender == g ? ThemeConfig.blueAccent : cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _selectedGender == g ? ThemeConfig.blueAccent : cardBorder),
                                  ),
                                  child: Center(child: Text(g[0].toUpperCase() + g.substring(1), style: TextStyle(color: _selectedGender == g ? Colors.white : textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 14),
                          _field('Date of Birth (YYYY-MM-DD)', _dobController, isDark, textPrimary, textSecondary, cardBorder, hint: '2000-01-25'),
                        ]),
                        const SizedBox(height: 20),
                        _sectionTitle('Password', textPrimary),
                        _card(cardBg, cardBorder, [
                          _passField('Password', _passwordController, isDark, textPrimary, textSecondary, cardBorder, isObscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                          const SizedBox(height: 14),
                          _passField('Confirm Password', _confirmPasswordController, isDark, textPrimary, textSecondary, cardBorder,
                            isObscure: _obscureConfirm,
                            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null),
                        ]),
                        const SizedBox(height: 20),
                        _sectionTitle('Address', textPrimary),
                        _card(cardBg, cardBorder, [
                          Row(children: [
                            Expanded(child: _field('Door No', _doorNoController, isDark, textPrimary, textSecondary, cardBorder)),
                            const SizedBox(width: 10),
                            Expanded(child: _field('Pincode', _pincodeController, isDark, textPrimary, textSecondary, cardBorder, keyboardType: TextInputType.number)),
                          ]),
                          const SizedBox(height: 14),
                          _field('Street Name', _streetController, isDark, textPrimary, textSecondary, cardBorder),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: _field('City', _cityController, isDark, textPrimary, textSecondary, cardBorder)),
                            const SizedBox(width: 10),
                            Expanded(child: _field('State', _stateController, isDark, textPrimary, textSecondary, cardBorder)),
                          ]),
                        ]),
                        const SizedBox(height: 20),
                        _sectionTitle('Identity', textPrimary),
                        _card(cardBg, cardBorder, [
                          _field('Occupation', _occupationController, isDark, textPrimary, textSecondary, cardBorder),
                          const SizedBox(height: 14),
                          _field('PAN Number', _panController, isDark, textPrimary, textSecondary, cardBorder),
                          const SizedBox(height: 14),
                          _field('Aadhar Number', _aadharController, isDark, textPrimary, textSecondary, cardBorder, keyboardType: TextInputType.number),
                        ]),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _isLoading ? null : _submitForm,
                          child: Container(
                            width: double.infinity, height: 54,
                            decoration: BoxDecoration(gradient: ThemeConfig.blueGradient, borderRadius: BorderRadius.circular(14)),
                            child: Center(child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Member', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: TextStyle(color: c, fontSize: 16, fontWeight: FontWeight.bold)));
  Widget _card(Color bg, Color border, List<Widget> children) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.2)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _field(String label, TextEditingController ctrl, bool isDark, Color tp, Color ts, Color cb, {TextInputType keyboardType = TextInputType.text, String? hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboardType,
        style: TextStyle(color: tp, fontSize: 13),
        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint ?? label, hintStyle: TextStyle(color: ts.withAlpha(80), fontSize: 12),
          filled: true, fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    ]);
  }

  Widget _passField(String label, TextEditingController ctrl, bool isDark, Color tp, Color ts, Color cb, {required bool isObscure, required VoidCallback onToggle, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, obscureText: isObscure,
        style: TextStyle(color: tp, fontSize: 13),
        validator: validator ?? (val) { if (val == null || val.isEmpty) return 'Required'; if (val.length < 6) return 'Min 6 chars'; return null; },
        decoration: InputDecoration(
          filled: true, fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: IconButton(icon: Icon(isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: ts, size: 18), onPressed: onToggle),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    ]);
  }
}
