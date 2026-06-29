import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/constellation_background.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/HR/add_employees.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/StartUp-Screens/theme_config.dart';

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
      final response = await http.get(Uri.parse('http://192.168.1.54:8000/api/registered-employees/'));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() => _employees = List<Map<String, dynamic>>.from(data['employees']));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
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
                    Text('Registered Employees', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_employees.length} registrations', style: TextStyle(color: textSecondary, fontSize: 11)),
                  ])),
                  IconButton(icon: const Icon(Icons.refresh_rounded, color: _green), onPressed: _fetchEmployees),
                ]),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _green))
                    : _employees.isEmpty
                        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.people_outline_rounded, color: Colors.grey, size: 60),
                            const SizedBox(height: 16),
                            Text('No registrations yet', style: TextStyle(color: textSecondary, fontSize: 16)),
                          ]))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _employees.length,
                            itemBuilder: (context, index) {
                              final emp = _employees[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _EmployeeDetailPage(employee: emp))).then((_) => _fetchEmployees()),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder, width: 1.2)),
                                  child: Row(children: [
                                    Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_green, Color(0xFF38F9D7)]), borderRadius: BorderRadius.circular(14)),
                                      child: Center(child: Text(
                                        '${emp['first_name']?[0] ?? '?'}${emp['last_name']?[0] ?? ''}',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      )),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text('${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 3),
                                      Text(emp['personal_email'] ?? '', style: TextStyle(color: textSecondary, fontSize: 12)),
                                      Text(emp['mobile'] ?? '', style: TextStyle(color: textSecondary, fontSize: 12)),
                                    ])),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      _statusBadge(emp['status'] ?? 'pending'),
                                      const SizedBox(height: 8),
                                      Icon(Icons.arrow_forward_ios_rounded, color: textSecondary, size: 14),
                                    ]),
                                  ]),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved': color = _green; break;
      case 'rejected': color = Colors.redAccent; break;
      default: color = const Color(0xFFF7971E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(6), border: Border.all(color: color)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
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

  Future<void> _verifyEmployee() async {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddEmployeePage(employee: widget.employee),
    ));
  }

  Future<void> _rejectEmployee() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ThemeConfig.getCardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Employee?', style: TextStyle(color: ThemeConfig.getTextPrimary(context), fontWeight: FontWeight.bold)),
        content: Text('Rejection email will be sent to the employee.', style: TextStyle(color: ThemeConfig.getTextSecondary(context))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: ThemeConfig.getTextSecondary(context)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.54:8000/api/reject-employee/${widget.employee['id']}/'),
        headers: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? 'Rejected!'),
        backgroundColor: Colors.redAccent,
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  void _viewDoc(String url) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _DocViewerPage(url: url)));
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
                  Text('Employee Details', style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _statusBadge(emp['status'] ?? 'pending'),
                ]),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // Profile Header
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_green, Color(0xFF38F9D7)]), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text(
                            '${emp['first_name']?[0] ?? '?'}${emp['last_name']?[0] ?? ''}',
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(emp['personal_email'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(emp['mobile'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Personal
                    _section('Personal Details', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Gender', emp['gender'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Date of Birth', emp['dob'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Blood Group', emp['blood_group'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Nationality', emp['nationality'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Marital Status', emp['marital_status'] ?? '-', textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Current Address
                    _section('Current Address', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Door No', emp['current_door'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Street', emp['current_street'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Area / Landmark', emp['current_address2'] ?? '-', textPrimary, textSecondary),
                      _infoRow('City', emp['current_city'] ?? '-', textPrimary, textSecondary),
                      _infoRow('State', emp['current_state'] ?? '-', textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Permanent Address
                    _section('Permanent Address', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Door No', emp['permanent_door'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Street', emp['permanent_street'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Area / Landmark', emp['permanent_address2'] ?? '-', textPrimary, textSecondary),
                      _infoRow('City', emp['permanent_city'] ?? '-', textPrimary, textSecondary),
                      _infoRow('State', emp['permanent_state'] ?? '-', textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Emergency
                    _section('Emergency Contact', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Name', emp['emergency_name'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Relationship', emp['emergency_relationship'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Contact', emp['emergency_contact'] ?? '-', textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Identity
                    _section('Identity', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Aadhaar', emp['aadhar'] ?? '-', textPrimary, textSecondary),
                      _infoRow('PAN', emp['pan'] ?? '-', textPrimary, textSecondary),
                      if ((emp['passport'] ?? '').isNotEmpty) _infoRow('Passport', emp['passport'], textPrimary, textSecondary),
                      if ((emp['driving_license'] ?? '').isNotEmpty) _infoRow('Driving License', emp['driving_license'], textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Education
                    _section('Education', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Qualification', emp['qualification'] ?? '-', textPrimary, textSecondary),
                      _infoRow('College', emp['college'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Year of Passing', emp['year_of_passing'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Percentage/CGPA', emp['percentage'] ?? '-', textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Bank
                    _section('Bank Details', cardBg, cardBorder, textPrimary, textSecondary, [
                      _infoRow('Account Holder', emp['account_holder'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Bank Name', emp['bank_name'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Account Number', emp['account_number'] ?? '-', textPrimary, textSecondary),
                      _infoRow('IFSC Code', emp['ifsc_code'] ?? '-', textPrimary, textSecondary),
                      _infoRow('Branch', emp['branch_name'] ?? '-', textPrimary, textSecondary),
                    ]),
                    const SizedBox(height: 12),

                    // Previous Employment
                    if (emp['is_experienced'] == true) ...[
                      _section('Previous Employment', cardBg, cardBorder, textPrimary, textSecondary, [
                        _infoRow('Company', emp['prev_company'] ?? '-', textPrimary, textSecondary),
                        _infoRow('Designation', emp['prev_designation'] ?? '-', textPrimary, textSecondary),
                        _infoRow('Experience', '${emp['prev_experience'] ?? '-'} years', textPrimary, textSecondary),
                        _infoRow('Last Working Day', emp['prev_last_working_day'] ?? '-', textPrimary, textSecondary),
                      ]),
                      const SizedBox(height: 12),
                    ],

                    // Documents
                    _docSection('Mandatory Documents', mandatoryDocs, cardBg, cardBorder, textPrimary, textSecondary),
                    const SizedBox(height: 12),
                    _docSection('Educational Documents', educationDocs, cardBg, cardBorder, textPrimary, textSecondary),
                    const SizedBox(height: 12),
                    if (emp['is_experienced'] == true) ...[
                      _docSection('Experienced Documents', experiencedDocs, cardBg, cardBorder, textPrimary, textSecondary),
                      const SizedBox(height: 12),
                    ],
                    _docSection('Optional Documents', optionalDocs, cardBg, cardBorder, textPrimary, textSecondary, optional: true),
                    const SizedBox(height: 20),

                    // Approve / Reject buttons
                    Row(children: [
                      Expanded(child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _verifyEmployee,
                        icon: const Icon(Icons.verified_rounded, size: 18),
                        label: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: _rejectEmployee,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      )),
                    ]),
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

  Widget _docSection(String title, Map<String, String> docs, Color cardBg, Color cardBorder, Color tp, Color ts, {bool optional = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder, width: 1.2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.bold)),
          if (optional) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(40), borderRadius: BorderRadius.circular(6)),
              child: const Text('Optional', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        ...docs.entries.map((entry) {
          final hasDoc = entry.value.isNotEmpty && entry.value != 'null';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key, style: TextStyle(color: ts, fontSize: 12, fontWeight: FontWeight.w500)),
                if (hasDoc)
                  const Text('✅ Uploaded', style: TextStyle(color: Color(0xFF43E97B), fontSize: 10))
                else
                  const Text('❌ Not uploaded', style: TextStyle(color: Colors.redAccent, fontSize: 10)),
              ])),
              if (hasDoc)
                GestureDetector(
                  onTap: () => _viewDoc(entry.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FACFE).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4FACFE)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.visibility_rounded, color: Color(0xFF4FACFE), size: 14),
                      SizedBox(width: 4),
                      Text('View', style: TextStyle(color: Color(0xFF4FACFE), fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withAlpha(60))),
                  child: const Text('No Doc', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ),
            ]),
          );
        }).toList(),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved': color = _green; break;
      case 'rejected': color = Colors.redAccent; break;
      default: color = const Color(0xFFF7971E);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _section(String title, Color cardBg, Color cardBorder, Color tp, Color ts, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder, width: 1.2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...rows,
      ]),
    );
  }

  Widget _infoRow(String label, String value, Color tp, Color ts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: TextStyle(color: ts, fontSize: 12))),
        Expanded(flex: 3, child: Text(value, textAlign: TextAlign.right, style: TextStyle(color: tp, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// Document Viewer Page
class _DocViewerPage extends StatelessWidget {
  final String url;
  const _DocViewerPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Document View', style: TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator(color: Color(0xFF43E97B))),
            errorBuilder: (_, __, ___) => const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.broken_image_rounded, color: Colors.white54, size: 80),
              SizedBox(height: 16),
              Text('Cannot load document', style: TextStyle(color: Colors.white54)),
            ]),
          ),
        ),
      ),
    );
  }
}