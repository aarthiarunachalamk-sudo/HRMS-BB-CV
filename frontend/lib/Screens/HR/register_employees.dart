import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/utils/privacy_utils.dart';
import 'package:hrms_mobileapp_bitbyte/utils/india_locations.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'add_employees.dart';

/// Returns a widget showing the employee's passport photo if available,
/// otherwise falls back to an initials circle.
Widget _employeeAvatar(
  Map<String, dynamic> employee, {
  double size = 60,
  double borderRadius = 16, // kept for API compat, ignored — always circular
}) {
  final photoUrl = '${employee['doc_passport_photo'] ?? ''}'.trim();
  final firstName = '${employee['first_name'] ?? ''}'.trim();
  final lastName = '${employee['last_name'] ?? ''}'.trim();
  final initials =
      '${firstName.isNotEmpty ? firstName[0] : '?'}${lastName.isNotEmpty ? lastName[0] : ''}'
          .toUpperCase();

  if (photoUrl.isNotEmpty) {
    return ClipOval(
      child: Image.network(
        photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsBox(initials, size: size),
      ),
    );
  }
  return _initialsBox(initials, size: size);
}

Widget _initialsBox(
  String initials, {
  double size = 60,
  double borderRadius = 16, // kept for API compat, ignored — always circular
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF4FACFE).withAlpha(28),
      border: Border.all(color: const Color(0xFF4FACFE).withAlpha(90)),
    ),
    child: Center(
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFF4FACFE),
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

class RegisterEmployeesPage extends StatefulWidget {
  const RegisterEmployeesPage({super.key});

  @override
  State<RegisterEmployeesPage> createState() => _RegisterEmployeesPageState();
}

class _RegisterEmployeesPageState extends State<RegisterEmployeesPage> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  static const Color _green = Color(0xFF43E97B);

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(ApiConfig.uri('/registered-employees/'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(
          () => _employees = List<Map<String, dynamic>>.from(data['employees']),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);

    return Scaffold(
      body: ConstellationBackground(
        accentColor: _green,
        child: SafeArea(
          child: Column(
            children: [
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registered Employees',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_employees.length} registrations',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: _green,
                  onRefresh: _fetchEmployees,
                  child: _employeeList(
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    cardBg: cardBg,
                    cardBorder: cardBorder,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _employeeList({
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBg,
    required Color cardBorder,
  }) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 260),
          Center(child: CircularProgressIndicator(color: _green)),
        ],
      );
    }

    if (_employees.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 220),
          const Icon(
            Icons.people_outline_rounded,
            color: Colors.grey,
            size: 60,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No registrations yet',
              style: TextStyle(color: textSecondary, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        final firstName = '${emp['first_name'] ?? ''}';
        final lastName = '${emp['last_name'] ?? ''}';

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _EmployeeDetailPage(employee: emp),
            ),
          ).then((_) => _fetchEmployees()),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: 1.2),
            ),
            child: Row(
              children: [
                _employeeAvatar(emp, size: 52, borderRadius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName'.trim(),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${emp['personal_email'] ?? ''}',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      Text(
                        maskMobileNumber(emp['mobile']),
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _statusBadge('${emp['status'] ?? 'pending'}'),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: textSecondary,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = _green;
        break;
      case 'rejected':
        color = Colors.redAccent;
        break;
      default:
        color = const Color(0xFFF7971E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmployeeDetailPage extends StatefulWidget {
  final Map<String, dynamic> employee;
  const _EmployeeDetailPage({required this.employee});

  @override
  State<_EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<_EmployeeDetailPage> {
  static const Color _green = Color(0xFF43E97B);
  bool _savingEdit = false;

  bool get _canEdit => '${widget.employee['status'] ?? 'pending'}' != 'approved';

  Future<void> _verifyEmployee() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEmployeePage(employee: widget.employee),
      ),
    );
    if (changed == true && mounted) {
      setState(() => widget.employee['status'] = 'approved');
      Navigator.pop(context, true);
    }
  }

  Future<void> _editEmployeeDetails() async {
    if (!_canEdit || _savingEdit) return;
    setState(() => _savingEdit = true);
    try {
      final response = await http.get(
        ApiConfig.uri('/registered-employees/${widget.employee['id']}/'),
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['success'] != true || decoded['employee'] is! Map) {
        throw Exception(decoded is Map ? decoded['message'] ?? 'Unable to load employee details.' : 'Unable to load employee details.');
      }
      if (!mounted) return;
      final editable = Map<String, dynamic>.from(decoded['employee'] as Map);
      final updated = await _showEmployeeEditSheet(editable);
      if (updated == null) return;
      final saveResponse = await http.patch(
        ApiConfig.uri('/registered-employees/${widget.employee['id']}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updated),
      );
      final saveData = jsonDecode(saveResponse.body);
      if (!mounted) return;
      if (saveData is! Map ||
          saveResponse.statusCode < 200 ||
          saveResponse.statusCode >= 300 ||
          saveData['success'] != true) {
        throw Exception(
          saveData is Map
              ? saveData['message'] ?? 'Unable to save employee details.'
              : 'Unable to save employee details.',
        );
      }
      if (saveData['employee'] is Map) {
        setState(() {
          widget.employee
            ..clear()
            ..addAll(Map<String, dynamic>.from(saveData['employee'] as Map));
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${saveData['message'] ?? 'Employee details updated.'}'),
          backgroundColor: _green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Edit failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _savingEdit = false);
    }
  }

  Future<Map<String, dynamic>?> _showEmployeeEditSheet(Map<String, dynamic> emp) async {
    final controllers = <String, TextEditingController>{};
    TextEditingController ctrl(String key) {
      return controllers.putIfAbsent(
        key,
        () => TextEditingController(text: '${emp[key] ?? ''}'),
      );
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThemeConfig.getCardBg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(builder: (sheetContext, setSheetState) {
          final tp = ThemeConfig.getTextPrimary(sheetContext);
          final ts = ThemeConfig.getTextSecondary(sheetContext);
          return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Employee Details',
                        style: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close_rounded, color: ts),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _editGroup('Basic', [
                  _editField('First Name', ctrl('first_name')),
                  _editField('Last Name', ctrl('last_name')),
                  _editField('Email', ctrl('personal_email'), keyboard: TextInputType.emailAddress),
                  _editField('Mobile', ctrl('mobile'), keyboard: TextInputType.phone),
                  _editField('Gender', ctrl('gender')),
                  _editField('Date of Birth', ctrl('dob')),
                  _editField('Blood Group', ctrl('blood_group')),
                  _editField('Marital Status', ctrl('marital_status')),
                  _editField('Nationality', ctrl('nationality')),
                ]),
                _editGroup('Current Address', [
                  _editField('Door No', ctrl('current_door')),
                  _editField('Street', ctrl('current_street')),
                  _editField('Area / Landmark', ctrl('current_address2')),
                  _editLocationDropdown('State', ctrl('current_state'), indiaStates, (value) {
                    setSheetState(() {
                      ctrl('current_state').text = value;
                      ctrl('current_city').clear();
                    });
                  }),
                  _editLocationDropdown('City', ctrl('current_city'), indiaCitiesForState(ctrl('current_state').text), (value) {
                    setSheetState(() => ctrl('current_city').text = value);
                  }),
                ]),
                _editGroup('Permanent Address', [
                  _editField('Door No', ctrl('permanent_door')),
                  _editField('Street', ctrl('permanent_street')),
                  _editField('Area / Landmark', ctrl('permanent_address2')),
                  _editLocationDropdown('State', ctrl('permanent_state'), indiaStates, (value) {
                    setSheetState(() {
                      ctrl('permanent_state').text = value;
                      ctrl('permanent_city').clear();
                    });
                  }),
                  _editLocationDropdown('City', ctrl('permanent_city'), indiaCitiesForState(ctrl('permanent_state').text), (value) {
                    setSheetState(() => ctrl('permanent_city').text = value);
                  }),
                ]),
                _editGroup('Emergency Contact', [
                  _editField('Name', ctrl('emergency_name')),
                  _editField('Relationship', ctrl('emergency_relationship')),
                  _editField('Contact', ctrl('emergency_contact'), keyboard: TextInputType.phone),
                ]),
                _editGroup('Identity', [
                  _editField('Aadhaar', ctrl('aadhar'), keyboard: TextInputType.number),
                  _editField('PAN', ctrl('pan')),
                  _editField('Passport', ctrl('passport')),
                  _editField('Driving License', ctrl('driving_license')),
                ]),
                _editGroup('Education', [
                  _editField('Qualification', ctrl('qualification')),
                  _editField('College', ctrl('college')),
                  _editField('Year of Passing', ctrl('year_of_passing'), keyboard: TextInputType.number),
                  _editField('Percentage / CGPA', ctrl('percentage')),
                ]),
                _editGroup('Bank', [
                  _editField('Account Holder', ctrl('account_holder')),
                  _editField('Bank Name', ctrl('bank_name')),
                  _editField('Account Number', ctrl('account_number'), keyboard: TextInputType.number),
                  _editField('IFSC Code', ctrl('ifsc_code')),
                  _editField('Branch', ctrl('branch_name')),
                ]),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext, {
                      for (final entry in controllers.entries) entry.key: entry.value.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          );
        });
      },
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    return result;
  }

  Future<void> _rejectEmployee() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeConfig.getCardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Employee?',
          style: TextStyle(
            color: ThemeConfig.getTextPrimary(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Rejection email will be sent to the employee.',
          style: TextStyle(color: ThemeConfig.getTextSecondary(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ThemeConfig.getTextSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Reject',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await http.post(
        ApiConfig.uri('/reject-employee/${widget.employee['id']}/'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'Rejected!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      if (!mounted) return;
      setState(() => widget.employee['status'] = 'rejected');
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _viewDoc(String title, String documentKey, String url) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DocViewerPage(
          title: title,
          url: url,
          onFlag: () => _flagDocument(title, documentKey),
        ),
      ),
    );
  }

  Future<bool> _flagDocument(String title, String documentKey) async {
    String issueType = 'Name mismatch';
    String priority = 'Medium';
    final remarkCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeConfig.getCardBg(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Flag Document Issue',
            style: TextStyle(
              color: ThemeConfig.getTextPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ThemeConfig.getTextSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                AppDropdownButtonFormField<String>(
                  value: issueType,
                  dropdownColor: ThemeConfig.getCardBg(context),
                  decoration: const InputDecoration(labelText: 'Issue Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Name mismatch',
                      child: Text('Name mismatch'),
                    ),
                    DropdownMenuItem(
                      value: 'Blurry document',
                      child: Text('Blurry document'),
                    ),
                    DropdownMenuItem(
                      value: 'Wrong document',
                      child: Text('Wrong document'),
                    ),
                    DropdownMenuItem(
                      value: 'Expired document',
                      child: Text('Expired document'),
                    ),
                    DropdownMenuItem(
                      value: 'Details not visible',
                      child: Text('Details not visible'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => issueType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: remarkCtrl,
                  maxLines: 3,
                  style: TextStyle(color: ThemeConfig.getTextPrimary(context)),
                  decoration: const InputDecoration(
                    labelText: 'HR Remark',
                    hintText: 'Enter correction details',
                  ),
                ),
                const SizedBox(height: 12),
                AppDropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: ThemeConfig.getCardBg(context),
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => priority = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: ThemeConfig.getTextSecondary(context)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Send Correction',
                style: TextStyle(
                  color: Color(0xFF4FACFE),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) {
      remarkCtrl.dispose();
      return false;
    }

    try {
      final response = await http.post(
        ApiConfig.uri(
          '/registered-employees/${widget.employee['id']}/documents/action/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'document_key': documentKey,
          'action': 'flag',
          'issue_type': issueType,
          'remark': remarkCtrl.text.trim(),
          'suggested_action': 'Re-upload the correct document',
          'priority': priority,
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return false;
      if (data['success'] == true) {
        if (data['employee'] is Map) {
          setState(() {
            widget.employee
              ..clear()
              ..addAll(Map<String, dynamic>.from(data['employee'] as Map));
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${data['message'] ?? 'Correction request sent to employee.'}',
            ),
            backgroundColor: data['email_sent'] == false
                ? Colors.redAccent
                : const Color(0xFFF7971E),
          ),
        );
        return true;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data['message'] ?? 'Unable to flag document.'}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      remarkCtrl.dispose();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = ThemeConfig.getTextPrimary(context);
    final textSecondary = ThemeConfig.getTextSecondary(context);
    final cardBg = ThemeConfig.getCardBg(context);
    final cardBorder = ThemeConfig.getCardBorder(context);
    final emp = widget.employee;

    // Document fields
    final Map<String, String> mandatoryDocs = {
      'Passport Size Photo': emp['doc_passport_photo'] ?? '',
      'Aadhaar Card Copy': emp['doc_aadhar'] ?? '',
      'PAN Card Copy': emp['doc_pan'] ?? '',
      'Bank Passbook': emp['doc_bank_passbook'] ?? '',
    };
    final Map<String, String> educationDocs = {
      '10th Marksheet': emp['doc_10th'] ?? '',
      '12th / Diploma': emp['doc_12th'] ?? '',
      'Degree Certificate': emp['doc_degree'] ?? '',
      'Consolidated Marksheet': emp['doc_consolidated'] ?? '',
      'NOC Certificate from College': emp['doc_college_noc'] ?? '',
    };
    final Map<String, String> experiencedDocs = {
      'Resume/CV': emp['doc_resume'] ?? '',
      'Experience Certificate': emp['doc_experience_cert'] ?? '',
      'Relieving Letter': emp['doc_relieving'] ?? '',
      'Salary Slips': emp['doc_salary_slips'] ?? '',
    };
    final Map<String, String> optionalDocs = {
      'Passport Copy': emp['doc_passport_copy'] ?? '',
      'Driving License Copy': emp['doc_driving'] ?? '',
      'Vaccination Certificate': emp['doc_vaccination'] ?? '',
    };

    return Scaffold(
      body: ConstellationBackground(
        accentColor: _green,
        child: SafeArea(
          child: Column(
            children: [
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
                      'Employee Details',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_canEdit) ...[
                      IconButton(
                        tooltip: 'Edit employee details',
                        onPressed: _savingEdit ? null : _editEmployeeDetails,
                        icon: _savingEdit
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.edit_rounded),
                        color: const Color(0xFF4FACFE),
                      ),
                      const SizedBox(width: 4),
                    ],
                    _statusBadge(emp['status'] ?? 'pending'),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardBorder, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            _employeeAvatar(emp),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    emp['personal_email'] ?? '',
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    maskMobileNumber(emp['mobile']),
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Personal
                      _section(
                        'Personal Details',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Gender',
                            emp['gender'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Date of Birth',
                            emp['dob'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Blood Group',
                            emp['blood_group'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Nationality',
                            emp['nationality'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Marital Status',
                            emp['marital_status'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Current Address
                      _section(
                        'Current Address',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Door No',
                            emp['current_door'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Street',
                            emp['current_street'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Area / Landmark',
                            emp['current_address2'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'City',
                            emp['current_city'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'State',
                            emp['current_state'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Permanent Address
                      _section(
                        'Permanent Address',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Door No',
                            emp['permanent_door'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Street',
                            emp['permanent_street'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Area / Landmark',
                            emp['permanent_address2'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'City',
                            emp['permanent_city'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'State',
                            emp['permanent_state'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Emergency
                      _section(
                        'Emergency Contact',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Name',
                            emp['emergency_name'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Relationship',
                            emp['emergency_relationship'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Contact',
                            emp['emergency_contact'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Identity
                      _section(
                        'Identity',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Aadhaar',
                            emp['aadhar'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          if ((emp['doc_aadhar'] ?? '').isNotEmpty &&
                              emp['doc_aadhar'] != 'null')
                            _docPhotoRow(
                              'Aadhaar Document',
                              emp['doc_aadhar'] as String,
                              'doc_aadhar',
                              cardBg,
                              cardBorder,
                              textPrimary,
                              textSecondary,
                            ),
                          _infoRow(
                            'PAN',
                            emp['pan'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          if ((emp['doc_pan'] ?? '').isNotEmpty &&
                              emp['doc_pan'] != 'null')
                            _docPhotoRow(
                              'PAN Card Document',
                              emp['doc_pan'] as String,
                              'doc_pan',
                              cardBg,
                              cardBorder,
                              textPrimary,
                              textSecondary,
                            ),
                          if ((emp['passport'] ?? '').isNotEmpty)
                            _infoRow(
                              'Passport',
                              emp['passport'],
                              textPrimary,
                              textSecondary,
                            ),
                          if ((emp['driving_license'] ?? '').isNotEmpty)
                            _infoRow(
                              'Driving License',
                              emp['driving_license'],
                              textPrimary,
                              textSecondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Education
                      _section(
                        'Education',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Qualification',
                            emp['qualification'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'College',
                            emp['college'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Year of Passing',
                            emp['year_of_passing'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Percentage/CGPA',
                            emp['percentage'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bank
                      _section(
                        'Bank Details',
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        [
                          _infoRow(
                            'Account Holder',
                            emp['account_holder'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Bank Name',
                            emp['bank_name'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Account Number',
                            emp['account_number'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'IFSC Code',
                            emp['ifsc_code'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          _infoRow(
                            'Branch',
                            emp['branch_name'] ?? '-',
                            textPrimary,
                            textSecondary,
                          ),
                          if ((emp['doc_bank_passbook'] ?? '').isNotEmpty &&
                              emp['doc_bank_passbook'] != 'null')
                            _docPhotoRow(
                              'Bank Passbook',
                              emp['doc_bank_passbook'] as String,
                              'doc_bank_passbook',
                              cardBg,
                              cardBorder,
                              textPrimary,
                              textSecondary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Previous Employment
                      if (emp['is_experienced'] == true) ...[
                        _section(
                          'Previous Employment',
                          cardBg,
                          cardBorder,
                          textPrimary,
                          textSecondary,
                          [
                            _infoRow(
                              'Company',
                              emp['prev_company'] ?? '-',
                              textPrimary,
                              textSecondary,
                            ),
                            _infoRow(
                              'Designation',
                              emp['prev_designation'] ?? '-',
                              textPrimary,
                              textSecondary,
                            ),
                            _infoRow(
                              'Experience',
                              '${emp['prev_experience'] ?? '-'} years',
                              textPrimary,
                              textSecondary,
                            ),
                            _infoRow(
                              'Last Working Day',
                              emp['prev_last_working_day'] ?? '-',
                              textPrimary,
                              textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Documents
                      _docSection(
                        'Mandatory Documents',
                        mandatoryDocs,
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                      ),
                      const SizedBox(height: 12),
                      _docSection(
                        'Educational Documents',
                        educationDocs,
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                      ),
                      const SizedBox(height: 12),
                      if (emp['is_experienced'] == true) ...[
                        _docSection(
                          'Experienced Documents',
                          experiencedDocs,
                          cardBg,
                          cardBorder,
                          textPrimary,
                          textSecondary,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _docSection(
                        'Optional Documents',
                        optionalDocs,
                        cardBg,
                        cardBorder,
                        textPrimary,
                        textSecondary,
                        optional: true,
                      ),
                      const SizedBox(height: 20),

                      if (_canEdit)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green.withAlpha(22),
                                  foregroundColor: _green,
                                  elevation: 0,
                                  side: BorderSide(color: _green.withAlpha(80)),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _verifyEmployee,
                                icon: const Icon(
                                  Icons.verified_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Verify',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withAlpha(20),
                                  foregroundColor: Colors.redAccent,
                                  elevation: 0,
                                  side: BorderSide(
                                    color: Colors.redAccent.withAlpha(75),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: _rejectEmployee,
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text(
                                  'Reject',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editGroup(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: ThemeConfig.getTextPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: TextStyle(color: ThemeConfig.getTextPrimary(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: ThemeConfig.getTextSecondary(context)),
          filled: true,
          fillColor: ThemeConfig.getCardBg(context),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: ThemeConfig.getCardBorder(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4FACFE)),
          ),
        ),
      ),
    );
  }

  Widget _editLocationDropdown(
    String label,
    TextEditingController controller,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final value = options.contains(controller.text) ? controller.text : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppDropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        menuMaxHeight: 300,
        dropdownColor: ThemeConfig.getCardBg(context),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: ThemeConfig.getCardBg(context),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        hint: Text(label == 'City' && options.isEmpty ? 'Select state first' : 'Select $label'),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }

  Widget _docSection(
    String title,
    Map<String, String> docs,
    Color cardBg,
    Color cardBorder,
    Color tp,
    Color ts, {
    bool optional = false,
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
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tp,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (optional) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Optional',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...docs.entries.map((entry) {
            final hasDoc = entry.value.isNotEmpty && entry.value != 'null';
            final documentKey = _documentKey(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            color: ts,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasDoc)
                          const Text(
                            '✅ Uploaded',
                            style: TextStyle(
                              color: Color(0xFF43E97B),
                              fontSize: 10,
                            ),
                          )
                        else
                          const Text(
                            '❌ Not uploaded',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasDoc)
                    GestureDetector(
                      onTap: () =>
                          _viewDoc(entry.key, documentKey, entry.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FACFE).withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4FACFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              color: Color(0xFF4FACFE),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'View',
                              style: TextStyle(
                                color: Color(0xFF4FACFE),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withAlpha(60)),
                      ),
                      child: const Text(
                        'No Doc',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = _green;
        break;
      case 'rejected':
        color = Colors.redAccent;
        break;
      default:
        color = const Color(0xFFF7971E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _documentKey(String title) {
    switch (title) {
      case 'Passport Size Photo':
        return 'doc_passport_photo';
      case 'Aadhaar Card Copy':
        return 'doc_aadhar';
      case 'PAN Card Copy':
        return 'doc_pan';
      case 'Bank Passbook':
        return 'doc_bank_passbook';
      case '10th Marksheet':
        return 'doc_10th';
      case '12th / Diploma':
        return 'doc_12th';
      case 'Degree Certificate':
        return 'doc_degree';
      case 'Consolidated Marksheet':
        return 'doc_consolidated';
      case 'NOC Certificate from College':
        return 'doc_college_noc';
      case 'Resume/CV':
        return 'doc_resume';
      case 'Experience Certificate':
        return 'doc_experience_cert';
      case 'Relieving Letter':
        return 'doc_relieving';
      case 'Salary Slips':
        return 'doc_salary_slips';
      case 'Passport Copy':
        return 'doc_passport_copy';
      case 'Driving License Copy':
        return 'doc_driving';
      case 'Vaccination Certificate':
        return 'doc_vaccination';
    }
    return '';
  }

  Widget _docPhotoRow(
    String label,
    String url,
    String documentKey,
    Color cardBg,
    Color cardBorder,
    Color tp,
    Color ts,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: ts,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _viewDoc(label, documentKey, url),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FACFE).withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF4FACFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Color(0xFF4FACFE),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'View',
                        style: TextStyle(
                          color: Color(0xFF4FACFE),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _viewDoc(label, documentKey, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4FACFE),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Cannot load image',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Divider(color: cardBorder, height: 1),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    Color cardBg,
    Color cardBorder,
    Color tp,
    Color ts,
    List<Widget> rows,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: tp,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color tp, Color ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: ts, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tp,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Document Viewer Page
class _DocViewerPage extends StatelessWidget {
  final String title;
  final String url;
  final Future<bool> Function() onFlag;

  const _DocViewerPage({
    required this.title,
    required this.url,
    required this.onFlag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final flagged = await onFlag();
              if (flagged && context.mounted) Navigator.pop(context);
            },
            icon: const Icon(
              Icons.flag_rounded,
              color: Color(0xFFF7971E),
              size: 18,
            ),
            label: const Text(
              'Flag',
              style: TextStyle(
                color: Color(0xFFF7971E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(color: Color(0xFF43E97B)),
                  ),
            errorBuilder: (_, __, ___) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white54,
                  size: 80,
                ),
                SizedBox(height: 16),
                Text(
                  'Cannot load document',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
