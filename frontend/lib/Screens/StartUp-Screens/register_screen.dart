import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'theme_config.dart';
import 'constellation_background.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // Page 1 - Personal
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  String _gender = 'male';
  final _dobCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentDoorCtrl = TextEditingController();
  final _currentStreetCtrl = TextEditingController();
  final _currentAddress2Ctrl = TextEditingController();
  final _currentCityCtrl = TextEditingController();
  final _currentStateCtrl = TextEditingController();
  final _permanentDoorCtrl = TextEditingController();
  final _permanentStreetCtrl = TextEditingController();
  final _permanentAddress2Ctrl = TextEditingController();
  final _permanentCityCtrl = TextEditingController();
  final _permanentStateCtrl = TextEditingController();
  bool _sameAsCurrent = false;
  String _maritalStatus = 'single';
  final _maritalOtherCtrl = TextEditingController();
  String _bloodGroup = 'A+';
  final _nationalityCtrl = TextEditingController();

  // Page 2 - Emergency + Identity
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyRelCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _passportCtrl = TextEditingController();
  final _drivingCtrl = TextEditingController();

  // Page 3 - Education + Bank
  final _qualificationCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _percentageCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  bool _isExperienced = false;

  // Page 4 - Previous Employment
  final _prevCompanyCtrl = TextEditingController();
  final _prevDesignationCtrl = TextEditingController();
  final _prevExperienceCtrl = TextEditingController();
  final _prevLastDayCtrl = TextEditingController();

  // Page 5 - Documents
  Map<String, File?> _mandatoryDocs = {
    'Passport Size Photo': null,
    'Aadhaar Card Copy': null,
    'PAN Card Copy': null,
    'Bank Passbook / Cancelled Cheque Copy': null,
  };
  Map<String, File?> _educationDocs = {
    '10th Marksheet': null,
    '12th Marksheet / Diploma Certificate': null,
    'Degree Certificate': null,
    'Consolidated Marksheet': null,
  };
  Map<String, File?> _experiencedDocs = {
    'Resume/CV': null,
    'Experience Certificate': null,
    'Relieving Letter': null,
    'Last 3 Months Salary Slips': null,
  };
  Map<String, File?> _optionalDocs = {
    'Passport Copy': null,
    'Driving License Copy': null,
    'Vaccination Certificate': null,
  };

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  int get _totalPages => _isExperienced ? 5 : 4;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _dobCtrl.dispose(); _mobileCtrl.dispose(); _emailCtrl.dispose();
    _currentDoorCtrl.dispose(); _currentStreetCtrl.dispose();
    _currentAddress2Ctrl.dispose(); _currentCityCtrl.dispose(); _currentStateCtrl.dispose();
    _permanentDoorCtrl.dispose(); _permanentStreetCtrl.dispose();
    _permanentAddress2Ctrl.dispose(); _permanentCityCtrl.dispose(); _permanentStateCtrl.dispose();
    _maritalOtherCtrl.dispose(); _nationalityCtrl.dispose();
    _emergencyNameCtrl.dispose(); _emergencyRelCtrl.dispose(); _emergencyContactCtrl.dispose();
    _aadharCtrl.dispose(); _panCtrl.dispose(); _passportCtrl.dispose(); _drivingCtrl.dispose();
    _qualificationCtrl.dispose(); _collegeCtrl.dispose(); _yearCtrl.dispose(); _percentageCtrl.dispose();
    _accountHolderCtrl.dispose(); _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose(); _ifscCtrl.dispose(); _branchCtrl.dispose();
    _prevCompanyCtrl.dispose(); _prevDesignationCtrl.dispose();
    _prevExperienceCtrl.dispose(); _prevLastDayCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      _submitForm();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 22),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: ThemeConfig.blueAccent)),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickFile(Map<String, File?> docMap, String key) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => docMap[key] = File(picked.path));
  }

  void _viewFile(File file) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FileViewerPage(file: file)));
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('http://192.168.1.54:8000/api/register-employee/');
      final request = http.MultipartRequest('POST', uri);

      // Text fields
      request.fields.addAll({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'gender': _gender,
        'dob': _dobCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'personal_email': _emailCtrl.text.trim(),
        'current_door': _currentDoorCtrl.text.trim(),
        'current_street': _currentStreetCtrl.text.trim(),
        'current_address2': _currentAddress2Ctrl.text.trim(),
        'current_city': _currentCityCtrl.text.trim(),
        'current_state': _currentStateCtrl.text.trim(),
        'permanent_door': _permanentDoorCtrl.text.trim(),
        'permanent_street': _permanentStreetCtrl.text.trim(),
        'permanent_address2': _permanentAddress2Ctrl.text.trim(),
        'permanent_city': _permanentCityCtrl.text.trim(),
        'permanent_state': _permanentStateCtrl.text.trim(),
        'marital_status': _maritalStatus,
        'marital_other': _maritalOtherCtrl.text.trim(),
        'blood_group': _bloodGroup,
        'nationality': _nationalityCtrl.text.trim(),
        'emergency_name': _emergencyNameCtrl.text.trim(),
        'emergency_relationship': _emergencyRelCtrl.text.trim(),
        'emergency_contact': _emergencyContactCtrl.text.trim(),
        'aadhar': _aadharCtrl.text.trim(),
        'pan': _panCtrl.text.trim().toUpperCase(),
        'passport': _passportCtrl.text.trim(),
        'driving_license': _drivingCtrl.text.trim(),
        'qualification': _qualificationCtrl.text.trim(),
        'college': _collegeCtrl.text.trim(),
        'year_of_passing': _yearCtrl.text.trim(),
        'percentage': _percentageCtrl.text.trim(),
        'account_holder': _accountHolderCtrl.text.trim(),
        'bank_name': _bankNameCtrl.text.trim(),
        'account_number': _accountNumberCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim().toUpperCase(),
        'branch_name': _branchCtrl.text.trim(),
        'is_experienced': _isExperienced.toString(),
        'prev_company': _prevCompanyCtrl.text.trim(),
        'prev_designation': _prevDesignationCtrl.text.trim(),
        'prev_experience': _prevExperienceCtrl.text.trim(),
        'prev_last_working_day': _prevLastDayCtrl.text.trim(),
      });

      // Document files
      final allDocs = {
        'doc_passport_photo': _mandatoryDocs['Passport Size Photo'],
        'doc_aadhar': _mandatoryDocs['Aadhaar Card Copy'],
        'doc_pan': _mandatoryDocs['PAN Card Copy'],
        'doc_bank_passbook': _mandatoryDocs['Bank Passbook / Cancelled Cheque Copy'],
        'doc_10th': _educationDocs['10th Marksheet'],
        'doc_12th': _educationDocs['12th Marksheet / Diploma Certificate'],
        'doc_degree': _educationDocs['Degree Certificate'],
        'doc_consolidated': _educationDocs['Consolidated Marksheet'],
        'doc_resume': _experiencedDocs['Resume/CV'],
        'doc_experience_cert': _experiencedDocs['Experience Certificate'],
        'doc_relieving': _experiencedDocs['Relieving Letter'],
        'doc_salary_slips': _experiencedDocs['Last 3 Months Salary Slips'],
        'doc_passport_copy': _optionalDocs['Passport Copy'],
        'doc_driving': _optionalDocs['Driving License Copy'],
        'doc_vaccination': _optionalDocs['Vaccination Certificate'],
      };

      for (final entry in allDocs.entries) {
        if (entry.value != null) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value!.path));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
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
              Text('Submitted!', style: TextStyle(color: ThemeConfig.getTextPrimary(context), fontWeight: FontWeight.bold)),
            ]),
            content: Text('Registration submitted!\nHR team will contact you soon.', style: TextStyle(color: ThemeConfig.getTextSecondary(context))),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFF4FACFE), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${data['errors'] ?? 'Failed'}'), backgroundColor: Colors.redAccent));
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

    final List<Widget> pages = [
      _buildPage1(isDark, textPrimary, textSecondary, cardBg, cardBorder),
      _buildPage2(isDark, textPrimary, textSecondary, cardBg, cardBorder),
      _buildPage3(isDark, textPrimary, textSecondary, cardBg, cardBorder),
      if (_isExperienced) _buildPage4(isDark, textPrimary, textSecondary, cardBg, cardBorder),
      _buildPage5(textPrimary, textSecondary, cardBg, cardBorder),
    ];

    final pageLabels = ['Personal', 'Identity', 'Education & Bank', if (_isExperienced) 'Experience', 'Documents'];

    return Scaffold(
      body: ConstellationBackground(
        accentColor: ThemeConfig.blueAccent,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  GestureDetector(
                    onTap: _currentPage > 0 ? _prevPage : () => Navigator.pop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cardBorder)),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Employee Registration', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Step ${_currentPage + 1} of ${pages.length} • ${pageLabels[_currentPage]}', style: TextStyle(color: textSecondary, fontSize: 11)),
                  ])),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(pages.length, (i) => Expanded(
                    child: Container(
                      height: 4, margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i <= _currentPage ? ThemeConfig.blueAccent : cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: pages,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: _isLoading ? null : _nextPage,
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(gradient: ThemeConfig.blueGradient, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentPage == pages.length - 1 ? 'Submit Registration' : 'Next',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          )),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1(bool isDark, Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Personal Details', tp),
        _card(cardBg, cardBorder, [
          _row([_field('First Name *', _firstNameCtrl, isDark, tp, ts, cardBorder), _field('Last Name *', _lastNameCtrl, isDark, tp, ts, cardBorder)]),
          const SizedBox(height: 14),
          _label('Gender *', ts),
          Row(children: ['male', 'female', 'other'].map((g) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _gender == g ? ThemeConfig.blueAccent : cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gender == g ? ThemeConfig.blueAccent : cardBorder),
                ),
                child: Center(child: Text(g[0].toUpperCase() + g.substring(1), style: TextStyle(color: _gender == g ? Colors.white : tp, fontSize: 12, fontWeight: FontWeight.w600))),
              ),
            ),
          )).toList()),
          const SizedBox(height: 14),
          _label('Date of Birth *', ts),
          _dateField('DD/MM/YYYY', _dobCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _label('Mobile Number * (10 digits)', ts),
          _textField('Mobile', _mobileCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.phone, maxLen: 10),
          const SizedBox(height: 14),
          _field('Personal Email ID *', _emailCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _label('Current Address *', ts),
          _field('Door No *', _currentDoorCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 10),
          _field('Street Name *', _currentStreetCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 10),
          _field('Area / Landmark *', _currentAddress2Ctrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 10),
          _row([_field('City *', _currentCityCtrl, isDark, tp, ts, cardBorder), _field('State *', _currentStateCtrl, isDark, tp, ts, cardBorder)]),
          const SizedBox(height: 10),
          Row(children: [
            Checkbox(
              value: _sameAsCurrent,
              activeColor: ThemeConfig.blueAccent,
              onChanged: (v) {
                setState(() {
                  _sameAsCurrent = v!;
                  if (_sameAsCurrent) {
                    _permanentDoorCtrl.text = _currentDoorCtrl.text;
                    _permanentStreetCtrl.text = _currentStreetCtrl.text;
                    _permanentAddress2Ctrl.text = _currentAddress2Ctrl.text;
                    _permanentCityCtrl.text = _currentCityCtrl.text;
                    _permanentStateCtrl.text = _currentStateCtrl.text;
                  }
                });
              },
            ),
            Text('Same as Current Address', style: TextStyle(color: ts, fontSize: 12)),
          ]),
          _label('Permanent Address *', ts),
          _field('Door No *', _permanentDoorCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 10),
          _field('Street Name *', _permanentStreetCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 10),
          _field('Area / Landmark *', _permanentAddress2Ctrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 10),
          _row([_field('City *', _permanentCityCtrl, isDark, tp, ts, cardBorder), _field('State *', _permanentStateCtrl, isDark, tp, ts, cardBorder)]),
          const SizedBox(height: 14),
          _label('Marital Status *', ts),
          _dropdown(_maritalStatus, ['single', 'married', 'other'], (v) => setState(() => _maritalStatus = v!), isDark, tp, cardBg, cardBorder),
          if (_maritalStatus == 'other') ...[
            const SizedBox(height: 10),
            _field('Specify Marital Status *', _maritalOtherCtrl, isDark, tp, ts, cardBorder),
          ],
          const SizedBox(height: 14),
          _label('Blood Group *', ts),
          _dropdown(_bloodGroup, _bloodGroups, (v) => setState(() => _bloodGroup = v!), isDark, tp, cardBg, cardBorder),
          const SizedBox(height: 14),
          _field('Nationality *', _nationalityCtrl, isDark, tp, ts, cardBorder),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildPage2(bool isDark, Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Emergency Contact', tp),
        _card(cardBg, cardBorder, [
          _field('Emergency Contact Name *', _emergencyNameCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _field('Relationship *', _emergencyRelCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _label('Contact Number * (10 digits)', ts),
          _textField('Contact Number', _emergencyContactCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.phone, maxLen: 10),
        ]),
        const SizedBox(height: 20),
        _sectionTitle('Identity Details', tp),
        _card(cardBg, cardBorder, [
          _label('Aadhaar Number * (12 digits)', ts),
          _textField('Aadhaar Number', _aadharCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.number, maxLen: 12),
          const SizedBox(height: 14),
          _label('PAN Number * (e.g. ABCDE1234F)', ts),
          _textField('PAN Number', _panCtrl, isDark, tp, ts, cardBorder, isUpperCase: true, maxLen: 10),
          const SizedBox(height: 14),
          _field('Passport Number (Optional)', _passportCtrl, isDark, tp, ts, cardBorder, required: false),
          const SizedBox(height: 14),
          _field('Driving License Number (Optional)', _drivingCtrl, isDark, tp, ts, cardBorder, required: false),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildPage3(bool isDark, Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Educational Details', tp),
        _card(cardBg, cardBorder, [
          _field('Qualification *', _qualificationCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _field('College / University *', _collegeCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _row([
            _textField('Year of Passing *', _yearCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.number, maxLen: 4),
            _textField('Percentage / CGPA *', _percentageCtrl, isDark, tp, ts, cardBorder),
          ]),
        ]),
        const SizedBox(height: 20),
        _sectionTitle('Bank Details', tp),
        _card(cardBg, cardBorder, [
          _field('Account Holder Name *', _accountHolderCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _field('Bank Name *', _bankNameCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _textField('Account Number *', _accountNumberCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          _textField('IFSC Code *', _ifscCtrl, isDark, tp, ts, cardBorder, isUpperCase: true, maxLen: 11),
          const SizedBox(height: 14),
          _field('Branch Name *', _branchCtrl, isDark, tp, ts, cardBorder),
        ]),
        const SizedBox(height: 20),
        _sectionTitle('Employment Type', tp),
        _card(cardBg, cardBorder, [
          Text('Are you a fresher or experienced?', style: TextStyle(color: ts, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isExperienced = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isExperienced ? ThemeConfig.blueAccent : cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: !_isExperienced ? ThemeConfig.blueAccent : cardBorder),
                ),
                child: Center(child: Text('Fresher', style: TextStyle(color: !_isExperienced ? Colors.white : tp, fontWeight: FontWeight.w600))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _isExperienced = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isExperienced ? ThemeConfig.blueAccent : cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isExperienced ? ThemeConfig.blueAccent : cardBorder),
                ),
                child: Center(child: Text('Experienced', style: TextStyle(color: _isExperienced ? Colors.white : tp, fontWeight: FontWeight.w600))),
              ),
            )),
          ]),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildPage4(bool isDark, Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Previous Employment', tp),
        _card(cardBg, cardBorder, [
          _field('Previous Company Name *', _prevCompanyCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _field('Designation *', _prevDesignationCtrl, isDark, tp, ts, cardBorder),
          const SizedBox(height: 14),
          _textField('Experience (Years) *', _prevExperienceCtrl, isDark, tp, ts, cardBorder, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          _label('Last Working Day *', ts),
          _dateField('DD/MM/YYYY', _prevLastDayCtrl, isDark, tp, ts, cardBorder),
        ]),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _buildPage5(Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionTitle('Documents Required', tp),
        _docSection('Mandatory Documents', _mandatoryDocs, tp, ts, cardBg, cardBorder),
        const SizedBox(height: 16),
        _docSection('Educational Documents', _educationDocs, tp, ts, cardBg, cardBorder),
        if (_isExperienced) ...[
          const SizedBox(height: 16),
          _docSection('Experienced Employees', _experiencedDocs, tp, ts, cardBg, cardBorder),
        ],
        const SizedBox(height: 16),
        _docSection('Optional Documents', _optionalDocs, tp, ts, cardBg, cardBorder, optional: true),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _docSection(String title, Map<String, File?> docs, Color tp, Color ts, Color cardBg, Color cardBorder, {bool optional = false}) {
    return _card(cardBg, cardBorder, [
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
      ...docs.keys.map((doc) {
        final file = docs[doc];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc, style: TextStyle(color: ts, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(children: [
              // Upload Button
              Expanded(child: GestureDetector(
                onTap: () => _pickFile(docs, doc),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: file != null ? const Color(0xFF43E97B).withAlpha(20) : ThemeConfig.blueAccent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: file != null ? const Color(0xFF43E97B) : ThemeConfig.blueAccent),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(file != null ? Icons.check_circle_rounded : Icons.upload_rounded,
                        color: file != null ? const Color(0xFF43E97B) : ThemeConfig.blueAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(file != null ? 'Uploaded ✅' : 'Upload Document',
                        style: TextStyle(color: file != null ? const Color(0xFF43E97B) : ThemeConfig.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
              // View Button — only show if uploaded
              if (file != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _viewFile(file),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FACFE).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF4FACFE)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.visibility_rounded, color: Color(0xFF4FACFE), size: 16),
                      SizedBox(width: 4),
                      Text('View', style: TextStyle(color: Color(0xFF4FACFE), fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ]),
            if (file != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('📎 ${file.path.split('/').last}', style: const TextStyle(color: Color(0xFF43E97B), fontSize: 10)),
              ),
          ]),
        );
      }).toList(),
    ]);
  }

  // Helper Widgets
  Widget _sectionTitle(String t, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.bold)),
  );

  Widget _card(Color bg, Color border, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1.2)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _row(List<Widget> children) => Row(
    children: children.map((w) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: w))).toList(),
  );

  Widget _label(String t, Color ts) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _field(String label, TextEditingController ctrl, bool isDark, Color tp, Color ts, Color cb, {TextInputType keyboard = TextInputType.text, bool required = true}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboard,
        style: TextStyle(color: tp, fontSize: 13),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null,
        decoration: _inputDec(label, isDark, cb),
      ),
    ]);
  }

  Widget _textField(String label, TextEditingController ctrl, bool isDark, Color tp, Color ts, Color cb, {TextInputType keyboard = TextInputType.text, int? maxLen, bool isUpperCase = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl, keyboardType: keyboard, maxLength: maxLen,
        textCapitalization: isUpperCase ? TextCapitalization.characters : TextCapitalization.none,
        style: TextStyle(color: tp, fontSize: 13),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: _inputDec(label, isDark, cb).copyWith(counterText: ''),
      ),
    ]);
  }

  Widget _dateField(String hint, TextEditingController ctrl, bool isDark, Color tp, Color ts, Color cb) {
    return TextFormField(
      controller: ctrl, readOnly: true,
      onTap: () => _pickDate(ctrl),
      style: TextStyle(color: tp, fontSize: 13),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: _inputDec(hint, isDark, cb).copyWith(
        suffixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF4FACFE), size: 18),
      ),
    );
  }

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged, bool isDark, Color tp, Color cardBg, Color cb) {
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
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i[0].toUpperCase() + i.substring(1)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, bool isDark, Color cb) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 12),
    filled: true,
    fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cb)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
  );
}

// File Viewer Page
class _FileViewerPage extends StatelessWidget {
  final File file;
  const _FileViewerPage({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(file.path.split('/').last, style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document saved!'))),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(file, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.insert_drive_file_rounded, color: Colors.white54, size: 80),
              SizedBox(height: 16),
              Text('Document Preview', style: TextStyle(color: Colors.white54, fontSize: 16)),
            ]),
          )),
        ),
      ),
    );
  }
}