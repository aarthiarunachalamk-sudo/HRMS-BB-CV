import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';

class CreateAdminsPage extends StatefulWidget {
  const CreateAdminsPage({super.key});

  @override
  State<CreateAdminsPage> createState() => _CreateAdminsPageState();
}

class _CreateAdminsPageState extends State<CreateAdminsPage> {
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
  String _selectedRole = 'ceo';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+91', 'name': 'India'},
    {'code': '+1', 'name': 'USA'},
    {'code': '+44', 'name': 'UK'},
    {'code': '+61', 'name': 'Australia'},
    {'code': '+971', 'name': 'UAE'},
  ];

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final latestDob = DateTime(now.year - 18, now.month, now.day);
    var initialDate = DateTime(now.year - 25, now.month, now.day);
    final currentValue = DateTime.tryParse(_dobController.text.trim());
    if (currentValue != null &&
        !currentValue.isBefore(DateTime(1950)) &&
        !currentValue.isAfter(latestDob)) {
      initialDate = currentValue;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      firstDate: DateTime(1950),
      lastDate: latestDob,
    );
    if (selected == null) return;

    _dobController.text =
        '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
  }

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
        ApiConfig.uri('/create-user/'),
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
          SnackBar(
            content: Text('✅ ${data['message']} — ID: ${data['user_id']}'),
            backgroundColor: Colors.green,
          ),
        );
        // Form clear pannunga
        _formKey.currentState!.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _dobController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _doorNoController.clear();
        _streetController.clear();
        _pincodeController.clear();
        _cityController.clear();
        _stateController.clear();
        _occupationController.clear();
        _panController.clear();
        _aadharController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${data['message'] ?? 'Error occurred'}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Server error: $e'),
          backgroundColor: Colors.redAccent,
        ),
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Admin',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                        // Role Selection
                        _buildSectionTitle('Role', textPrimary),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cardBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: AppDropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              dropdownColor: cardBg,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ceo',
                                  child: Text('CEO'),
                                ),
                                DropdownMenuItem(
                                  value: 'md',
                                  child: Text('MD'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedRole = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Basic Details
                        _buildSectionTitle('Basic Details', textPrimary),
                        _buildCard(
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          children: [
                            _buildRow([
                              _buildField(
                                'First Name',
                                _firstNameController,
                                isDark,
                                textPrimary,
                                textSecondary,
                                cardBorder,
                              ),
                              _buildField(
                                'Last Name',
                                _lastNameController,
                                isDark,
                                textPrimary,
                                textSecondary,
                                cardBorder,
                              ),
                            ]),
                            const SizedBox(height: 14),
                            _buildField(
                              'Email',
                              _emailController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            // Phone with country code
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 105,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Country Code',
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF0A121E)
                                              : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(color: cardBorder),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: AppDropdownButton<String>(
                                            value: _selectedCountryCode,
                                            isExpanded: true,
                                            dropdownColor: isDark
                                                ? const Color(0xFF0A121E)
                                                : Colors.white,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontSize: 13,
                                            ),
                                            items: _countryCodes.map((c) {
                                              return DropdownMenuItem(
                                                value: c['code'],
                                                child: Text(
                                                  '${c['code']} ${c['name']}',
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (val) => setState(
                                              () => _selectedCountryCode = val!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildField(
                                    'Phone',
                                    _phoneController,
                                    isDark,
                                    textPrimary,
                                    textSecondary,
                                    cardBorder,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Gender
                            Text(
                              'Gender',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: ['male', 'female', 'other']
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final index = entry.key;
                                    final g = entry.value;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _selectedGender = g),
                                        child: Container(
                                          margin: EdgeInsets.only(
                                            right: index < 2 ? 8 : 0,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _selectedGender == g
                                                ? ThemeConfig.blueAccent
                                                : cardBg,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: _selectedGender == g
                                                  ? ThemeConfig.blueAccent
                                                  : cardBorder,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              g[0].toUpperCase() +
                                                  g.substring(1),
                                              style: TextStyle(
                                                color: _selectedGender == g
                                                    ? Colors.white
                                                    : textPrimary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                            const SizedBox(height: 14),

                            // DOB
                            _buildField(
                              'Date of Birth',
                              _dobController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                              hint: 'Select from calendar',
                              readOnly: true,
                              onTap: _pickDob,
                              suffixIcon: const Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Password
                        _buildSectionTitle('Password', textPrimary),
                        _buildCard(
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          children: [
                            _buildPasswordField(
                              'Password',
                              _passwordController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                              isObscure: _obscurePassword,
                              onToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildPasswordField(
                              'Confirm Password',
                              _confirmPasswordController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                              isObscure: _obscureConfirm,
                              onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              validator: (val) {
                                if (val != _passwordController.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Address
                        _buildSectionTitle('Address', textPrimary),
                        _buildCard(
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          children: [
                            _buildRow([
                              _buildField(
                                'Door No',
                                _doorNoController,
                                isDark,
                                textPrimary,
                                textSecondary,
                                cardBorder,
                              ),
                              _buildField(
                                'Pincode',
                                _pincodeController,
                                isDark,
                                textPrimary,
                                textSecondary,
                                cardBorder,
                                keyboardType: TextInputType.number,
                              ),
                            ]),
                            const SizedBox(height: 14),
                            _buildField(
                              'Street Name',
                              _streetController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                            ),
                            const SizedBox(height: 14),
                            _buildRow([
                              _buildField(
                                'City',
                                _cityController,
                                isDark,
                                textPrimary,
                                textSecondary,
                                cardBorder,
                              ),
                              _buildField(
                                'State',
                                _stateController,
                                isDark,
                                textPrimary,
                                textSecondary,
                                cardBorder,
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Identity
                        _buildSectionTitle('Identity', textPrimary),
                        _buildCard(
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          children: [
                            _buildField(
                              'Occupation',
                              _occupationController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              'PAN Number',
                              _panController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              'Aadhar Number',
                              _aadharController,
                              isDark,
                              textPrimary,
                              textSecondary,
                              cardBorder,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        // Submit Button
                        GestureDetector(
                          onTap: _isLoading ? null : _submitForm,
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: ThemeConfig.blueGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: ThemeConfig.blueAccent.withAlpha(70),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Create Admin',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
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

  Widget _buildSectionTitle(String title, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color cardBg,
    required Color cardBorder,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.asMap().entries.map((entry) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: entry.key < children.length - 1 ? 8 : 0,
            ),
            child: entry.value,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(color: textPrimary, fontSize: 13),
          validator: (val) =>
              val == null || val.trim().isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(
              color: textSecondary.withAlpha(80),
              fontSize: 12,
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A121E)
                : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF00C6FF),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color cardBorder, {
    required bool isObscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          style: TextStyle(color: textPrimary, fontSize: 13),
          validator:
              validator ??
              (val) {
                if (val == null || val.isEmpty) return 'Required';
                if (val.length < 6) return 'Min 6 characters';
                return null;
              },
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0A121E)
                : const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: textSecondary,
                size: 18,
              ),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF00C6FF),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
