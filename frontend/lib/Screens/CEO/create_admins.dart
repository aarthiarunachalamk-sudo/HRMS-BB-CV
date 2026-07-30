import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/separated_date_picker.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/utils/india_locations.dart';
import 'ceo_widgets.dart';

// ─── Role list ────────────────────────────────────────────────
const _kRoles = [
  {'value': 'ceo', 'label': 'CEO', 'icon': Icons.workspace_premium_outlined},
  {'value': 'md', 'label': 'MD', 'icon': Icons.business_center_outlined},
  {
    'value': 'director',
    'label': 'Executive Director',
    'icon': Icons.apartment_outlined,
  },
  {'value': 'hr', 'label': 'HR', 'icon': Icons.badge_outlined},
  {
    'value': 'finance',
    'label': 'Finance',
    'icon': Icons.account_balance_outlined,
  },
  {
    'value': 'admin',
    'label': 'Admin',
    'icon': Icons.admin_panel_settings_outlined,
  },
  {
    'value': 'manager',
    'label': 'Manager',
    'icon': Icons.manage_accounts_outlined,
  },
  {'value': 'tl', 'label': 'Team Lead', 'icon': Icons.group_outlined},
  {'value': 'it', 'label': 'IT Team', 'icon': Icons.computer_outlined},
  {'value': 'marketing', 'label': 'Marketing', 'icon': Icons.campaign_outlined},
];

// ─── Country codes ────────────────────────────────────────────
String _roleLabelFromValue(String value) {
  final role = _kRoles.firstWhere(
    (item) => item['value'] == value,
    orElse: () => {'label': value},
  );
  return '${role['label']}';
}

const _kCountryCodes = [
  {'code': '+91', 'flag': '🇮🇳', 'name': 'India'},
  {'code': '+1', 'flag': '🇺🇸', 'name': 'USA'},
  {'code': '+44', 'flag': '🇬🇧', 'name': 'UK'},
  {'code': '+61', 'flag': '🇦🇺', 'name': 'Australia'},
  {'code': '+971', 'flag': '🇦🇪', 'name': 'UAE'},
  {'code': '+65', 'flag': '🇸🇬', 'name': 'Singapore'},
];

final _kStates = indiaStates;
const _kCitiesByState = indiaCitiesByState;

const _kCityAddressDefaults = {
  'Visakhapatnam': {'state': 'Andhra Pradesh', 'pincode': '530001'},
  'Vijayawada': {'state': 'Andhra Pradesh', 'pincode': '520001'},
  'Guntur': {'state': 'Andhra Pradesh', 'pincode': '522001'},
  'Tirupati': {'state': 'Andhra Pradesh', 'pincode': '517501'},
  'Bengaluru': {'state': 'Karnataka', 'pincode': '560001'},
  'Mysuru': {'state': 'Karnataka', 'pincode': '570001'},
  'Mangaluru': {'state': 'Karnataka', 'pincode': '575001'},
  'Hubballi': {'state': 'Karnataka', 'pincode': '580020'},
  'Thiruvananthapuram': {'state': 'Kerala', 'pincode': '695001'},
  'Kozhikode': {'state': 'Kerala', 'pincode': '673001'},
  'Thrissur': {'state': 'Kerala', 'pincode': '680001'},
  'Chennai': {'state': 'Tamil Nadu', 'pincode': '600001'},
  'Coimbatore': {'state': 'Tamil Nadu', 'pincode': '641001'},
  'Erode': {'state': 'Tamil Nadu', 'pincode': '638001'},
  'Hyderabad': {'state': 'Telangana', 'pincode': '500001'},
  'Kochi': {'state': 'Kerala', 'pincode': '682001'},
  'Madurai': {'state': 'Tamil Nadu', 'pincode': '625001'},
  'Mumbai': {'state': 'Maharashtra', 'pincode': '400001'},
  'Pune': {'state': 'Maharashtra', 'pincode': '411001'},
  'Nagpur': {'state': 'Maharashtra', 'pincode': '440001'},
  'Nashik': {'state': 'Maharashtra', 'pincode': '422001'},
  'Salem': {'state': 'Tamil Nadu', 'pincode': '636001'},
  'Tiruchirappalli': {'state': 'Tamil Nadu', 'pincode': '620001'},
  'Tirunelveli': {'state': 'Tamil Nadu', 'pincode': '627001'},
  'Vellore': {'state': 'Tamil Nadu', 'pincode': '632001'},
  'Warangal': {'state': 'Telangana', 'pincode': '506002'},
  'Karimnagar': {'state': 'Telangana', 'pincode': '505001'},
  'Nizamabad': {'state': 'Telangana', 'pincode': '503001'},
  'Lucknow': {'state': 'Uttar Pradesh', 'pincode': '226001'},
  'Noida': {'state': 'Uttar Pradesh', 'pincode': '201301'},
  'Kanpur': {'state': 'Uttar Pradesh', 'pincode': '208001'},
  'Varanasi': {'state': 'Uttar Pradesh', 'pincode': '221001'},
  'Agra': {'state': 'Uttar Pradesh', 'pincode': '282001'},
  'Kolkata': {'state': 'West Bengal', 'pincode': '700001'},
  'Howrah': {'state': 'West Bengal', 'pincode': '711101'},
  'Durgapur': {'state': 'West Bengal', 'pincode': '713201'},
  'Siliguri': {'state': 'West Bengal', 'pincode': '734001'},
};

String? _validateState(String? value) {
  final state = value?.trim() ?? '';
  if (state.isEmpty) return 'State is required';
  if (!_kCitiesByState.containsKey(state)) return 'Select a valid state';
  return null;
}

String? _validateCityForState(String state, String? value) {
  if (state.trim().isEmpty) return 'Select state first';
  final city = value?.trim() ?? '';
  if (city.isEmpty) return 'City is required';
  if (!(_kCitiesByState[state]?.contains(city) ?? false)) {
    return 'Select a city in $state';
  }
  return null;
}

const _kItAndTlDepartments = [
  'Web Application Development',
  'Mobile Application Development',
  'UI/UX Design',
  'Quality Assurance (QA) and Testing',
  'DevOps and Cloud Engineering',
  'Artificial Intelligence and Machine Learning',
  'Data Science and Analytics',
  'Cybersecurity',
  'IT Infrastructure and Network Support',
  'Technical Support',
  'Project Management',
  'Product Management',
  'Digital Marketing',
  'Sales and Business Development',
  'Human Resources (HR)',
  'Finance and Accounts',
  'Administration and Operations',
  'Management',
  'Research and Development (R&D)',
  'Internship / Trainee',
];

const _kWorkModes = ['Work From Home', 'Hybrid', 'OnSite'];

const _kWorkModeValues = {
  'Work From Home': 'work_from_home',
  'Hybrid': 'hybrid',
  'OnSite': 'onsite',
};

const _kHrDepartments = [
  'Talent Acquisition / Recruitment',
  'HR Operations',
  'Employee Onboarding and Offboarding',
  'Attendance and Leave Management',
  'Payroll and Compensation',
  'Benefits Administration',
  'Learning and Development (L&D)',
  'Performance Management',
  'Employee Relations',
  'Employee Engagement',
  'HR Compliance and Policies',
  'Workforce Planning',
  'HR Analytics and Reporting',
  'Health, Safety and Well-being',
  'Internship and Campus Recruitment',
];

const _kDepartmentValues = {
  'Web Application Development': 'web_application_development',
  'Mobile Application Development': 'mobile_application_development',
  'UI/UX Design': 'ui_ux_design',
  'Quality Assurance (QA) and Testing': 'quality_assurance_testing',
  'DevOps and Cloud Engineering': 'devops_cloud_engineering',
  'Artificial Intelligence and Machine Learning':
      'artificial_intelligence_machine_learning',
  'Data Science and Analytics': 'data_science_analytics',
  'Cybersecurity': 'cybersecurity',
  'IT Infrastructure and Network Support': 'it_infrastructure_network_support',
  'Technical Support': 'technical_support',
  'Project Management': 'project_management',
  'Product Management': 'product_management',
  'Digital Marketing': 'digital_marketing',
  'Sales and Business Development': 'sales_business_development',
  'Human Resources (HR)': 'human_resources',
  'Finance and Accounts': 'finance_accounts',
  'Administration and Operations': 'administration_operations',
  'Management': 'management',
  'Research and Development (R&D)': 'research_development',
  'Internship / Trainee': 'internship_trainee',
  'Talent Acquisition / Recruitment': 'talent_acquisition_recruitment',
  'HR Operations': 'hr_operations',
  'Employee Onboarding and Offboarding': 'employee_onboarding_offboarding',
  'Attendance and Leave Management': 'attendance_leave_management',
  'Payroll and Compensation': 'payroll_compensation',
  'Benefits Administration': 'benefits_administration',
  'Learning and Development (L&D)': 'learning_development',
  'Performance Management': 'performance_management',
  'Employee Relations': 'employee_relations',
  'Employee Engagement': 'employee_engagement',
  'HR Compliance and Policies': 'hr_compliance_policies',
  'Workforce Planning': 'workforce_planning',
  'HR Analytics and Reporting': 'hr_analytics_reporting',
  'Health, Safety and Well-being': 'health_safety_well_being',
  'Internship and Campus Recruitment': 'internship_campus_recruitment',
};

const _kRolesWithDepartmentSelection = {'hr', 'it', 'tl'};

bool _requiresDepartmentSelection(String role) =>
    _kRolesWithDepartmentSelection.contains(role);

String _assignedDepartmentLabel(String role) =>
    role == 'admin' ? 'Management' : _roleLabelFromValue(role);

String _assignedDepartmentValue(String role) =>
    role == 'admin' ? 'management' : role;

List<String> _departmentsForRole(String role) =>
    role == 'hr' ? _kHrDepartments : _kItAndTlDepartments;

String? _validateSelectedDepartment(String role, String? value) {
  final department = value?.trim() ?? '';
  if (department.isEmpty) {
    return 'Department is required for ${_roleLabelFromValue(role)}';
  }
  if (!_departmentsForRole(role).contains(department)) {
    return 'Select a valid department';
  }
  return null;
}

class CeoCreateAdminsPage extends StatefulWidget {
  final String createdBy;

  const CeoCreateAdminsPage({super.key, this.createdBy = ''});

  @override
  State<CeoCreateAdminsPage> createState() => _CeoCreateAdminsPageState();
}

class _CeoCreateAdminsPageState extends State<CeoCreateAdminsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _doorNo = TextEditingController();
  final _street = TextEditingController();
  final _pincode = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pan = TextEditingController();
  final _aadhar = TextEditingController();

  // State
  String _countryCode = '+91';
  String _gender = 'male';
  String _role = 'hr';
  String _department = '';
  String _workMode = 'OnSite';
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _loading = false;
  int _step = 0; // 0=role, 1=personal, 2=password, 3=address, 4=identity

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _dob,
      _password,
      _confirm,
      _doorNo,
      _street,
      _pincode,
      _city,
      _state,
      _pan,
      _aadhar,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Validators ───────────────────────────────────────────────
  String? _req(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  String? _validateName(String? v, String label) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return '$label is required';
    if (value.length < 2) return '$label must have at least 2 letters';
    if (!RegExp(r"^[A-Za-z]+(?:[ .'-][A-Za-z]+)*$").hasMatch(value)) {
      return 'Enter a valid $label';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePhone(String? v) {
    final digits = v?.trim() ?? '';
    if (digits.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d+$').hasMatch(digits)) return 'Only digits allowed';
    if (digits.length != 10) return 'Phone number must be 10 digits';
    return null;
  }

  String? _validateDob(String? v) {
    if (v == null || v.trim().isEmpty) return 'Date of birth is required';
    final re = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!re.hasMatch(v.trim())) return 'Use format YYYY-MM-DD';
    try {
      final d = DateTime.parse(v.trim());
      if (d.isAfter(DateTime.now())) return 'Date cannot be in the future';
      final age = DateTime.now().difference(d).inDays ~/ 365;
      if (age < 18) return 'Must be at least 18 years old';
    } catch (_) {
      return 'Invalid date';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Minimum 8 characters';
    if (!v.contains(RegExp(r'[A-Z]')))
      return 'Include at least one uppercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Include at least one number';
    if (!v.contains(RegExp(r'[!@#\$%^&*]')))
      return 'Include at least one special character';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  String? _validatePincode(String? v) {
    if (v == null || v.trim().isEmpty) return 'Pincode is required';
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim())) {
      return 'Enter a valid 6-digit Indian pincode';
    }
    return null;
  }

  String? _validatePan(String? v) {
    final pan = v?.trim().toUpperCase() ?? '';
    if (pan.isEmpty) return 'PAN number is required';
    // PAN: 3 alphabetic-series characters, a valid holder-type character,
    // holder-name initial, 4 digits, and an alphabetic check character.
    if (!RegExp(r'^[A-Z]{3}[PCHABGJLFTE][A-Z][0-9]{4}[A-Z]$').hasMatch(pan)) {
      return 'Enter a valid PAN (e.g. ABCPD1234F)';
    }
    return null;
  }

  String? _validateAadhar(String? v) {
    if (v == null || v.trim().isEmpty) return 'Aadhar number is required';
    if (!RegExp(r'^\d{12}$').hasMatch(v.trim().replaceAll(' ', ''))) {
      return 'Aadhar must be 12 digits';
    }
    return null;
  }

  // ── API submit ───────────────────────────────────────────────
  Future<void> _submit() async {
    final invalidStep = _firstInvalidStep();
    if (invalidStep != null) {
      setState(() => _step = invalidStep);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.validate();
      });
      _showError('Please correct all required fields before submitting.');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await http.post(
        ApiConfig.uri('/create-user/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'first_name': _firstName.text.trim(),
          'last_name': _lastName.text.trim(),
          'email': _email.text.trim(),
          'country_code': _countryCode,
          'phone': _phone.text.trim(),
          'gender': _gender,
          'dob': _dob.text.trim(),
          'password': _password.text,
          'confirm_password': _confirm.text,
          'door_no': _doorNo.text.trim(),
          'street': _street.text.trim(),
          'pincode': _pincode.text.trim(),
          'city': _city.text.trim(),
          'state': _state.text.trim(),
          'occupation': _role,
          'designation': _role,
          'department': _requiresDepartmentSelection(_role)
              ? (_kDepartmentValues[_department] ?? _department)
              : _assignedDepartmentValue(_role),
          'work_mode': _kWorkModeValues[_workMode] ?? 'onsite',
          'created_by': widget.createdBy,
          'pan': _pan.text.trim().toUpperCase(),
          'aadhar': _aadhar.text.trim().replaceAll(' ', ''),
          'role': _role,
        }),
      );
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is! Map) throw const FormatException();
        data = Map<String, dynamic>.from(decoded);
      } on FormatException {
        if (!mounted) return;
        _showError(
          res.statusCode >= 500
              ? 'Server error (${res.statusCode}). Check the Django console.'
              : 'Server returned an invalid response (${res.statusCode}).',
        );
        return;
      }
      if (!mounted) return;
      if (data['success'] == true) {
        _showSuccess(data['user_id'] ?? '');
      } else {
        _showError(_errorMessage(data));
      }
    } catch (_) {
      if (mounted)
        _showError('Cannot connect to server. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _firstInvalidStep() {
    if (_role.trim().isEmpty ||
        (_requiresDepartmentSelection(_role) &&
            _validateSelectedDepartment(_role, _department) != null) ||
        !_kWorkModes.contains(_workMode)) {
      return 0;
    }
    if (_validateName(_firstName.text, 'First name') != null ||
        _validateName(_lastName.text, 'Last name') != null ||
        _validateEmail(_email.text) != null ||
        _validatePhone(_phone.text) != null ||
        _validateDob(_dob.text) != null) {
      return 1;
    }
    if (_validatePassword(_password.text) != null ||
        _validateConfirm(_confirm.text) != null) {
      return 2;
    }
    if (_req(_doorNo.text, 'Door no.') != null ||
        _req(_street.text, 'Street') != null ||
        _validateState(_state.text) != null ||
        _validateCityForState(_state.text, _city.text) != null ||
        _validatePincode(_pincode.text) != null) {
      return 3;
    }
    if (_validatePan(_pan.text) != null ||
        _validateAadhar(_aadhar.text) != null) {
      return 4;
    }
    return null;
  }

  void _showSuccess(String userId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        userId: userId,
        role: _role,
        onDone: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(true); // return to CEO dashboard
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _dob,
      _password,
      _confirm,
      _doorNo,
      _street,
      _pincode,
      _city,
      _state,
      _pan,
      _aadhar,
    ]) {
      c.clear();
    }
    setState(() {
      _gender = 'male';
      _role = 'hr';
      _department = '';
      _workMode = 'OnSite';
      _step = 0;
    });
  }

  void _goToPreviousStep() {
    if (_loading || _step == 0) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step--);
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _step == 0 && !_loading,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goToPreviousStep();
      },
      child: CeoShell(
        title: 'Create Team Member',
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _StepIndicator(current: _step),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _buildStep(),
                  ),
                ),
              ),
              _NavButtons(
                step: _step,
                totalSteps: 6,
                loading: _loading,
                onBack: _goToPreviousStep,
                onNext: _handleNext,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _step++);
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepRole(
          role: _role,
          department: _department,
          workMode: _workMode,
          onChanged: (v) => setState(() {
            _role = v;
            _department = _requiresDepartmentSelection(v)
                ? ''
                : _assignedDepartmentLabel(v);
          }),
          onDepartmentChanged: (v) => setState(() => _department = v),
          onWorkModeChanged: (v) => setState(() => _workMode = v),
          key: const ValueKey(0),
        );
      case 1:
        return _StepPersonal(
          key: const ValueKey(1),
          firstName: _firstName,
          lastName: _lastName,
          email: _email,
          phone: _phone,
          dob: _dob,
          countryCode: _countryCode,
          gender: _gender,
          onCountryChanged: (v) => setState(() => _countryCode = v),
          onGenderChanged: (v) => setState(() => _gender = v),
          validateEmail: _validateEmail,
          validatePhone: _validatePhone,
          validateDob: _validateDob,
          validateName: _validateName,
        );
      case 2:
        return _StepPassword(
          key: const ValueKey(2),
          password: _password,
          confirm: _confirm,
          showPassword: _showPassword,
          showConfirm: _showConfirm,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onToggleConfirm: () => setState(() => _showConfirm = !_showConfirm),
          validatePassword: _validatePassword,
          validateConfirm: _validateConfirm,
        );
      case 3:
        return _StepAddress(
          key: const ValueKey(3),
          doorNo: _doorNo,
          street: _street,
          pincode: _pincode,
          city: _city,
          state: _state,
          onCityChanged: (value) => setState(() {
            _city.text = value;
            final defaults = _kCityAddressDefaults[value];
            if (defaults != null) {
              _pincode.text = defaults['pincode'] ?? _pincode.text;
            }
          }),
          onStateChanged: (value) => setState(() {
            _state.text = value;
            final validCities = _kCitiesByState[value] ?? const <String>[];
            if (!validCities.contains(_city.text)) {
              _city.clear();
              _pincode.clear();
            }
          }),
          req: _req,
          validatePincode: _validatePincode,
        );
      case 4:
        return _StepIdentity(
          key: const ValueKey(4),
          pan: _pan,
          aadhar: _aadhar,
          validatePan: _validatePan,
          validateAadhar: _validateAadhar,
        );
      case 5:
        return _StepReview(
          key: const ValueKey(5),
          role: _role,
          firstName: _firstName.text,
          lastName: _lastName.text,
          email: _email.text,
          countryCode: _countryCode,
          phone: _phone.text,
          gender: _gender,
          dob: _dob.text,
          doorNo: _doorNo.text,
          street: _street.text,
          pincode: _pincode.text,
          city: _city.text,
          state: _state.text,
          department: _department,
          workMode: _workMode,
          pan: _pan.text,
          aadhar: _aadhar.text,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _errorMessage(Map<String, dynamic> data) {
    final message = data['message'];
    if (message != null && '$message'.trim().isNotEmpty) return '$message';

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.entries.first;
      final value = first.value;
      if (value is List && value.isNotEmpty)
        return '${first.key}: ${value.first}';
      return '${first.key}: $value';
    }

    return 'Something went wrong';
  }
}

// ═══════════════════════════════════════════════════════════════
//  Step indicator
// ═══════════════════════════════════════════════════════════════
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  static const _labels = [
    'Role',
    'Personal',
    'Password',
    'Address',
    'Identity',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final done = stepIndex < current;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? CeoColors.cyan : CeoColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < current;
          final active = stepIndex == current;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? CeoColors.cyan
                      : active
                      ? CeoColors.cyan.withValues(alpha: 0.2)
                      : CeoColors.card,
                  border: Border.all(
                    color: (done || active) ? CeoColors.cyan : CeoColors.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 13,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: active ? CeoColors.cyan : CeoColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                width: 46,
                child: Text(
                  _labels[stepIndex],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: (done || active) ? CeoColors.cyan : CeoColors.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Nav buttons (Back / Next / Submit)
// ═══════════════════════════════════════════════════════════════
class _NavButtons extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _NavButtons({
    required this.step,
    required this.totalSteps,
    required this.loading,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CeoColors.border)),
      ),
      child: Row(
        children: [
          if (step > 0) ...[
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: CeoColors.muted,
                  side: const BorderSide(color: CeoColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: loading ? null : onBack,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: SizedBox(
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: loading ? null : (isLast ? onSubmit : onNext),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLast ? 'Create Member' : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Shared field widget
// ═══════════════════════════════════════════════════════════════
class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextCapitalization textCapitalization;
  final bool showLabel;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType = TextInputType.text,
    required this.validator,
    this.inputFormatters,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: const TextStyle(
              color: CeoColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: 1,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(
              color: CeoColors.muted.withValues(alpha: 0.5),
              fontSize: 13,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: CeoColors.cardAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.cyan, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF4B4B),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF4B4B),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Section heading
// ═══════════════════════════════════════════════════════════════
Future<String?> _showAnchoredMenu({
  required BuildContext context,
  required BuildContext anchorContext,
  required List<String> options,
  required String value,
  required double itemHeight,
  required int itemMaxLines,
  Widget Function(String option)? leadingBuilder,
}) {
  final anchor = anchorContext.findRenderObject() as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
  final origin = anchor.localToGlobal(
    Offset(0, anchor.size.height + 6),
    ancestor: overlay,
  );
  final menuRect = Rect.fromLTWH(origin.dx, origin.dy, anchor.size.width, 0);

  return showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(menuRect, Offset.zero & overlay.size),
    color: CeoColors.card,
    surfaceTintColor: Colors.transparent,
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: CeoColors.border),
    ),
    constraints: BoxConstraints(
      minWidth: anchor.size.width,
      maxWidth: anchor.size.width,
      maxHeight: 320,
    ),
    items: options.map((option) {
      final selected = option == value;
      return PopupMenuItem<String>(
        value: option,
        height: itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            if (leadingBuilder != null) ...[
              leadingBuilder(option),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                option,
                maxLines: itemMaxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check_rounded, color: CeoColors.cyan, size: 18),
            ],
          ],
        ),
      );
    }).toList(),
  );
}

class _AnchoredDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final List<String> options;
  final Widget prefixIcon;
  final ValueChanged<String> onChanged;
  final String? Function(String?) validator;

  const _AnchoredDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.prefixIcon,
    required this.onChanged,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: ValueKey('$label|$value|${options.length}'),
      initialValue: value.isEmpty ? null : value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CeoColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (anchorContext) => InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final next = await _showAnchoredMenu(
                  context: context,
                  anchorContext: anchorContext,
                  options: options,
                  value: value,
                  itemHeight: 64,
                  itemMaxLines: 2,
                );
                if (next != null) {
                  field.didChange(next);
                  onChanged(next);
                }
              },
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                decoration: BoxDecoration(
                  color: CeoColors.cardAlt,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: field.hasError
                        ? const Color(0xFFFF4B4B)
                        : CeoColors.border,
                    width: field.hasError ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    prefixIcon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        value.isEmpty ? hint : value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: value.isEmpty
                              ? CeoColors.muted.withValues(alpha: 0.55)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: CeoColors.muted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (field.hasError) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                field.errorText!,
                style: const TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnchoredRoleDropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _AnchoredRoleDropdownField({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedRole = _kRoles.firstWhere(
      (role) => role['value'] == value,
      orElse: () => _kRoles.first,
    );
    final labels = _kRoles
        .map((role) => role['label'] as String)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            color: CeoColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Builder(
          builder: (anchorContext) => InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final nextLabel = await _showAnchoredMenu(
                context: context,
                anchorContext: anchorContext,
                options: labels,
                value: selectedRole['label'] as String,
                itemHeight: 52,
                itemMaxLines: 1,
                leadingBuilder: (label) {
                  final role = _kRoles.firstWhere(
                    (item) => item['label'] == label,
                  );
                  return Icon(
                    role['icon'] as IconData,
                    color: label == selectedRole['label']
                        ? CeoColors.cyan
                        : CeoColors.muted,
                    size: 19,
                  );
                },
              );
              if (nextLabel != null) {
                final nextRole = _kRoles.firstWhere(
                  (role) => role['label'] == nextLabel,
                );
                onChanged(nextRole['value'] as String);
              }
            },
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
              decoration: BoxDecoration(
                color: CeoColors.cardAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: CeoColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedRole['icon'] as IconData,
                    color: CeoColors.cyan,
                    size: 19,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedRole['label'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: CeoColors.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final List<String> options;
  final Widget prefixIcon;
  final ValueChanged<String> onChanged;
  final String? Function(String?) validator;
  final double? itemHeight;
  final int itemMaxLines;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.prefixIcon,
    required this.onChanged,
    required this.validator,
    this.itemHeight,
    this.itemMaxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValue = options.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CeoColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        AppDropdownButtonFormField<String>(
          value: selectedValue,
          isExpanded: true,
          itemHeight: itemHeight,
          menuMaxHeight: 280,
          dropdownColor: CeoColors.card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: CeoColors.muted,
            size: 20,
          ),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hint: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              hint,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CeoColors.muted.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          selectedItemBuilder: (context) => options.map((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          items: options.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: itemMaxLines,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            filled: true,
            fillColor: CeoColors.cardAlt,
            prefixIcon: prefixIcon,
            contentPadding: const EdgeInsets.fromLTRB(0, 13, 12, 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.cyan, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF4B4B),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF4B4B),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AssignedDepartmentField extends StatelessWidget {
  final String value;

  const _AssignedDepartmentField({required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            color: CeoColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: CeoColors.cardAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CeoColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                color: CeoColors.cyan,
                size: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.lock_outline_rounded,
                color: CeoColors.muted,
                size: 17,
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Assigned automatically from the selected role.',
          style: TextStyle(color: CeoColors.muted, fontSize: 11, height: 1.35),
        ),
      ],
    );
  }
}

class _RoleDropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _RoleDropdownField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final values = _kRoles.map((role) => role['value'] as String).toList();
    final selectedValue = values.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            color: CeoColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        AppDropdownButtonFormField<String>(
          value: selectedValue,
          isExpanded: true,
          isDense: true,
          alignment: AlignmentDirectional.centerStart,
          itemHeight: 52,
          menuMaxHeight: 280,
          dropdownColor: CeoColors.card,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: CeoColors.muted,
            size: 20,
          ),
          selectedItemBuilder: (context) => _kRoles.map((role) {
            return _RoleDropdownContent(role: role, isSelected: true);
          }).toList(),
          items: _kRoles.map((role) {
            return DropdownMenuItem<String>(
              value: role['value'] as String,
              alignment: Alignment.centerLeft,
              child: _RoleDropdownContent(role: role, isSelected: false),
            );
          }).toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
          validator: (next) =>
              next == null || next.trim().isEmpty ? 'Role is required' : null,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            filled: true,
            fillColor: CeoColors.cardAlt,
            contentPadding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CeoColors.cyan, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF4B4B),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFFF4B4B),
                width: 1.5,
              ),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleDropdownContent extends StatelessWidget {
  final Map<String, Object> role;
  final bool isSelected;

  const _RoleDropdownContent({required this.role, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final label = role['label'] as String;
    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          role['icon'] as IconData,
          color: isSelected ? CeoColors.cyan : CeoColors.muted,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CeoColors.cyan, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Divider(color: CeoColors.border.withValues(alpha: 0.6), height: 16),
          ...children,
        ],
      ),
    );
  }
}

// Spacing helper between fields
const _gap = SizedBox(height: 14);

// ═══════════════════════════════════════════════════════════════
//  Step 0 — Role selection
// ═══════════════════════════════════════════════════════════════
class _StepRole extends StatelessWidget {
  final String role;
  final String department;
  final String workMode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onDepartmentChanged;
  final ValueChanged<String> onWorkModeChanged;

  const _StepRole({
    required this.role,
    required this.department,
    required this.workMode,
    required this.onChanged,
    required this.onDepartmentChanged,
    required this.onWorkModeChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Select Role',
      icon: Icons.manage_accounts_rounded,
      children: [
        const Text(
          'Choose the role this team member will have in the system.',
          style: TextStyle(color: CeoColors.muted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 16),
        _AnchoredRoleDropdownField(value: role, onChanged: onChanged),
        const SizedBox(height: 16),
        if (_requiresDepartmentSelection(role))
          _AnchoredDropdownField(
            label: 'Department *',
            value: department,
            hint: 'Select department',
            options: _departmentsForRole(role),
            prefixIcon: const Icon(
              Icons.apartment_rounded,
              color: CeoColors.muted,
              size: 18,
            ),
            onChanged: onDepartmentChanged,
            validator: (value) => _validateSelectedDepartment(role, value),
          )
        else
          _AssignedDepartmentField(value: _assignedDepartmentLabel(role)),
        const SizedBox(height: 16),
        _AnchoredDropdownField(
          label: 'Work Mode *',
          value: workMode,
          hint: 'Select work mode',
          options: _kWorkModes,
          prefixIcon: const Icon(
            Icons.work_outline_rounded,
            color: CeoColors.muted,
            size: 18,
          ),
          onChanged: onWorkModeChanged,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Work mode is required'
              : null,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Step 1 — Personal Details
// ═══════════════════════════════════════════════════════════════
class _StepPersonal extends StatefulWidget {
  final TextEditingController firstName, lastName, email, phone, dob;
  final String countryCode, gender;
  final ValueChanged<String> onCountryChanged, onGenderChanged;
  final String? Function(String?) validateEmail, validatePhone, validateDob;
  final String? Function(String?, String) validateName;

  const _StepPersonal({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.dob,
    required this.countryCode,
    required this.gender,
    required this.onCountryChanged,
    required this.onGenderChanged,
    required this.validateEmail,
    required this.validatePhone,
    required this.validateDob,
    required this.validateName,
  });

  @override
  State<_StepPersonal> createState() => _StepPersonalState();
}

class _StepPersonalState extends State<_StepPersonal> {
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final latestDob = DateTime(now.year - 18, now.month, now.day);
    DateTime initial = now.subtract(const Duration(days: 365 * 25));
    if (widget.dob.text.trim().isNotEmpty) {
      try {
        initial = DateTime.parse(widget.dob.text.trim());
      } catch (_) {}
    }
    final picked = await showSeparatedDatePicker(
      context: context,
      initialDate: initial,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      firstDate: DateTime(1950),
      lastDate: latestDob,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: CeoColors.cyan,
            onPrimary: Colors.white,
            surface: Color(0xFF0D1B2E),
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: const Color(0xFF0D1B2E),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      widget.dob.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = widget.dob.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Basic Information',
          icon: Icons.person_outline_rounded,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'First Name',
                    controller: widget.firstName,
                    hint: 'e.g. John',
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: CeoColors.muted,
                      size: 18,
                    ),
                    validator: (v) => widget.validateName(v, 'First name'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    label: 'Last Name',
                    controller: widget.lastName,
                    hint: 'e.g. Smith',
                    textCapitalization: TextCapitalization.words,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: CeoColors.muted,
                      size: 18,
                    ),
                    validator: (v) => widget.validateName(v, 'Last name'),
                  ),
                ),
              ],
            ),
            _gap,
            _Field(
              label: 'Email Address',
              controller: widget.email,
              hint: 'name@company.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: CeoColors.muted,
                size: 18,
              ),
              validator: widget.validateEmail,
            ),
            _gap,
            // Phone with country code
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phone Number',
                  style: TextStyle(
                    color: CeoColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country code picker
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: CeoColors.cardAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: CeoColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: AppDropdownButton<String>(
                          value: widget.countryCode,
                          dropdownColor: CeoColors.card,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: CeoColors.muted,
                            size: 18,
                          ),
                          items: _kCountryCodes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c['code'],
                                  child: Text('${c['flag']}  ${c['code']}'),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) widget.onCountryChanged(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        label: 'Phone Number',
                        controller: widget.phone,
                        hint: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: CeoColors.muted,
                          size: 18,
                        ),
                        validator: widget.validatePhone,
                        showLabel: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        _Section(
          title: 'Personal Details',
          icon: Icons.cake_outlined,
          children: [
            // Gender selector
            const Text(
              'Gender',
              style: TextStyle(
                color: CeoColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(3, (index) {
                final g = ['male', 'female', 'other'][index];
                final selected = widget.gender == g;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => widget.onGenderChanged(g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: selected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF00C6FF),
                                    Color(0xFF0072FF),
                                  ],
                                )
                              : null,
                          color: selected ? null : CeoColors.cardAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF0072FF)
                                : CeoColors.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${g[0].toUpperCase()}${g.substring(1)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            _gap,
            // Date of Birth — calendar picker
            FormField<String>(
              validator: (_) => widget.validateDob(widget.dob.text),
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date of Birth',
                      style: TextStyle(
                        color: CeoColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () async {
                        await _pickDate();
                        field.didChange(widget.dob.text);
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: CeoColors.cardAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: field.hasError
                                ? Colors.redAccent
                                : hasDate
                                ? CeoColors.cyan.withAlpha(160)
                                : CeoColors.border,
                            width: hasDate ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              color: hasDate ? CeoColors.cyan : CeoColors.muted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                hasDate
                                    ? widget.dob.text
                                    : 'Select date of birth',
                                style: TextStyle(
                                  color: hasDate
                                      ? Colors.white
                                      : CeoColors.muted,
                                  fontSize: 13,
                                  fontWeight: hasDate
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: CeoColors.muted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (field.hasError) ...[
                      const SizedBox(height: 5),
                      Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Step 2 — Password
// ═══════════════════════════════════════════════════════════════
class _StepPassword extends StatelessWidget {
  final TextEditingController password, confirm;
  final bool showPassword, showConfirm;
  final VoidCallback onTogglePassword, onToggleConfirm;
  final String? Function(String?) validatePassword, validateConfirm;

  const _StepPassword({
    super.key,
    required this.password,
    required this.confirm,
    required this.showPassword,
    required this.showConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.validatePassword,
    required this.validateConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Set Password',
      icon: Icons.lock_outline_rounded,
      children: [
        // Password rules hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CeoColors.cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CeoColors.cyan.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: CeoColors.cyan,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Password Requirements',
                    style: TextStyle(
                      color: CeoColors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...[
                '• Minimum 8 characters',
                '• At least one uppercase letter (A-Z)',
                '• At least one number (0-9)',
                '• At least one special character (!@#\$%^&*)',
              ].map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    r,
                    style: const TextStyle(
                      color: CeoColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _gap,
        _Field(
          label: 'Password',
          controller: password,
          hint: 'Enter password',
          obscureText: !showPassword,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: CeoColors.muted,
            size: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: CeoColors.muted,
              size: 18,
            ),
            onPressed: onTogglePassword,
          ),
          validator: validatePassword,
        ),
        _gap,
        _Field(
          label: 'Confirm Password',
          controller: confirm,
          hint: 'Re-enter password',
          obscureText: !showConfirm,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: CeoColors.muted,
            size: 18,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: CeoColors.muted,
              size: 18,
            ),
            onPressed: onToggleConfirm,
          ),
          validator: validateConfirm,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Step 3 — Address
// ═══════════════════════════════════════════════════════════════
class _StepAddress extends StatelessWidget {
  final TextEditingController doorNo, street, pincode, city, state;
  final ValueChanged<String> onCityChanged, onStateChanged;
  final String? Function(String?, String) req;
  final String? Function(String?) validatePincode;

  const _StepAddress({
    super.key,
    required this.doorNo,
    required this.street,
    required this.pincode,
    required this.city,
    required this.state,
    required this.onCityChanged,
    required this.onStateChanged,
    required this.req,
    required this.validatePincode,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Address Details',
      icon: Icons.location_on_outlined,
      children: [
        _Field(
          label: 'Door / Flat No.',
          controller: doorNo,
          hint: 'e.g. 12B',
          prefixIcon: const Icon(
            Icons.home_outlined,
            color: CeoColors.muted,
            size: 18,
          ),
          validator: (v) => req(v, 'Door no.'),
        ),
        _gap,
        _Field(
          label: 'Street / Area',
          controller: street,
          hint: 'e.g. Anna Nagar, 2nd Street',
          textCapitalization: TextCapitalization.words,
          prefixIcon: const Icon(
            Icons.streetview_outlined,
            color: CeoColors.muted,
            size: 18,
          ),
          validator: (v) => req(v, 'Street'),
        ),
        _gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DropdownField(
                label: 'State',
                value: state.text,
                hint: 'Select state',
                options: _kStates,
                prefixIcon: const Icon(
                  Icons.map_outlined,
                  color: CeoColors.muted,
                  size: 18,
                ),
                onChanged: onStateChanged,
                validator: _validateState,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DropdownField(
                label: 'City',
                value: city.text,
                hint: state.text.isEmpty ? 'Select state first' : 'Select city',
                options: _kCitiesByState[state.text] ?? const <String>[],
                prefixIcon: const Icon(
                  Icons.location_city_outlined,
                  color: CeoColors.muted,
                  size: 18,
                ),
                onChanged: onCityChanged,
                validator: (v) => _validateCityForState(state.text, v),
              ),
            ),
          ],
        ),
        _gap,
        _Field(
          label: 'Pincode',
          controller: pincode,
          hint: 'Auto-filled from city',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: const Icon(
            Icons.pin_drop_outlined,
            color: CeoColors.muted,
            size: 18,
          ),
          validator: validatePincode,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Step 4 — Identity
// ═══════════════════════════════════════════════════════════════
class _StepIdentity extends StatelessWidget {
  final TextEditingController pan, aadhar;
  final String? Function(String?) validatePan, validateAadhar;

  const _StepIdentity({
    super.key,
    required this.pan,
    required this.aadhar,
    required this.validatePan,
    required this.validateAadhar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Identity Documents',
          icon: Icons.badge_outlined,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CeoColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CeoColors.gold.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security_rounded, color: CeoColors.gold, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This information is encrypted and stored securely.',
                      style: TextStyle(
                        color: CeoColors.muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _gap,
            _Field(
              label: 'PAN Number',
              controller: pan,
              hint: 'e.g. ABCDE1234F',
              textCapitalization: TextCapitalization.characters,
              prefixIcon: const Icon(
                Icons.credit_card_outlined,
                color: CeoColors.muted,
                size: 18,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(10),
                _UpperCaseFormatter(),
              ],
              validator: validatePan,
            ),
            _gap,
            _Field(
              label: 'Aadhar Number',
              controller: aadhar,
              hint: 'e.g. 1234 5678 9012',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(
                Icons.fingerprint_rounded,
                color: CeoColors.muted,
                size: 18,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: validateAadhar,
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Step 5 — Review
// ═══════════════════════════════════════════════════════════════
class _StepReview extends StatelessWidget {
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String countryCode;
  final String phone;
  final String gender;
  final String dob;
  final String doorNo;
  final String street;
  final String pincode;
  final String city;
  final String state;
  final String department;
  final String workMode;
  final String pan;
  final String aadhar;

  const _StepReview({
    super.key,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.countryCode,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.doorNo,
    required this.street,
    required this.pincode,
    required this.city,
    required this.state,
    required this.department,
    required this.workMode,
    required this.pan,
    required this.aadhar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'Review Member Details',
          icon: Icons.fact_check_outlined,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CeoColors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CeoColors.green.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: CeoColors.green,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please verify all details before creating this team member.',
                      style: TextStyle(
                        color: CeoColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _gap,
            _ReviewGroup(
              title: 'Role',
              rows: [
                _ReviewRowData('Member Role', _roleLabel(role)),
                _ReviewRowData(
                  'Department',
                  department.isEmpty ? '-' : department,
                ),
                _ReviewRowData('Designation', _roleLabelFromValue(role)),
                _ReviewRowData('Work Mode', workMode),
              ],
            ),
            _gap,
            _ReviewGroup(
              title: 'Basic Information',
              rows: [
                _ReviewRowData('Name', '$firstName $lastName'.trim()),
                _ReviewRowData('Email', email),
                _ReviewRowData('Phone', '$countryCode ${_maskPhone(phone)}'),
                _ReviewRowData('Gender', _title(gender)),
                _ReviewRowData('Date of Birth', dob),
              ],
            ),
            _gap,
            _ReviewGroup(
              title: 'Address',
              rows: [
                _ReviewRowData('Door / Flat No.', doorNo),
                _ReviewRowData('Street / Area', street),
                _ReviewRowData('City', city),
                _ReviewRowData('State', state),
                _ReviewRowData('Pincode', pincode),
              ],
            ),
            _gap,
            _ReviewGroup(
              title: 'Identity',
              rows: [
                _ReviewRowData('PAN Number', _maskPan(pan)),
                _ReviewRowData('Aadhar Number', _maskAadhar(aadhar)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _roleLabel(String value) {
    final role = _kRoles.firstWhere(
      (item) => item['value'] == value,
      orElse: () => {'label': value},
    );
    return '${role['label']}';
  }

  String _title(String value) {
    if (value.isEmpty) return '-';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String _maskAadhar(String value) {
    final digits = value.replaceAll(' ', '');
    if (digits.length <= 4) return digits;
    return 'XXXX XXXX ${digits.substring(digits.length - 4)}';
  }

  String _maskPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 3) return digits;
    final hiddenCount = digits.length - 3;
    final hidden = List.filled(hiddenCount, 'X').join();
    return '${digits.substring(0, 2)}$hidden${digits.substring(digits.length - 1)}';
  }

  String _maskPan(String value) {
    final normalized = value.replaceAll(' ', '').toUpperCase();
    if (normalized.length != 10) return normalized;
    const visibleIndexes = {0, 4, 8, 9};
    return List.generate(
      normalized.length,
      (index) => visibleIndexes.contains(index) ? normalized[index] : 'X',
    ).join();
  }
}

class _ReviewRowData {
  final String label;
  final String value;

  const _ReviewRowData(this.label, this.value);
}

class _ReviewGroup extends StatelessWidget {
  final String title;
  final List<_ReviewRowData> rows;

  const _ReviewGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CeoColors.cardAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CeoColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CeoColors.cyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((row) => _ReviewRow(row.label, row.value)),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                color: CeoColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upper-case formatter for PAN ──────────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// ═══════════════════════════════════════════════════════════════
//  Success dialog
// ═══════════════════════════════════════════════════════════════
class _SuccessDialog extends StatelessWidget {
  final String userId;
  final String role;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.userId,
    required this.role,
    required this.onDone,
  });

  String get _roleLabel {
    final match = _kRoles.firstWhere(
      (r) => r['value'] == role,
      orElse: () => {'label': role},
    );
    return match['label'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: CeoColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CeoColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Check circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CeoColors.green.withValues(alpha: 0.12),
                border: Border.all(
                  color: CeoColors.green.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: CeoColors.green,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Team Member Created!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'New $_roleLabel has been added successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: CeoColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (userId.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: CeoColors.cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CeoColors.cyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: CeoColors.cyan,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'User ID: $userId',
                      style: const TextStyle(
                        color: CeoColors.cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Login credentials have been sent to their email.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CeoColors.muted,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CeoColors.muted,
                      side: const BorderSide(color: CeoColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onDone,
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onDone,
                      child: const Text(
                        'Go Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
