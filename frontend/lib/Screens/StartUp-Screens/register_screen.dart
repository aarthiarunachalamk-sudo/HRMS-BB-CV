import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/separated_date_picker.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_dropdown.dart';
import 'package:hrms_mobileapp_bitbyte/widgets/app_greeting.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:hrms_mobileapp_bitbyte/backend/api_config.dart';
import 'package:hrms_mobileapp_bitbyte/utils/india_locations.dart';
import 'package:hrms_mobileapp_bitbyte/utils/nationalities.dart';
import 'theme_config.dart';
import 'constellation_background.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _maxUploadBytes = 25 * 1024 * 1024;
  final String _submissionKey =
      'mobile-${DateTime.now().microsecondsSinceEpoch}';

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _submissionPopupVisible = false;
  final ValueNotifier<String> _submissionStatus = ValueNotifier(
    'Preparing your registration...',
  );
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
  final _nationalityCtrl = TextEditingController(text: 'Indian');

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
  final _universityCtrl = TextEditingController();
  final _collegeCtrl = TextEditingController();
  final _otherCollegeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _percentageCtrl = TextEditingController();
  final _cgpaCtrl = TextEditingController();
  final _accountHolderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  bool _isExperienced = false;
  bool _showAccountNumber = false;
  bool _isSyncingScores = false;

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
    'Consolidated Marksheet': null,
    'NOC Certificate from College': null,
  };
  Map<String, File?> _experiencedDocs = {
    'Resume/CV': null,
    'Experience Certificate': null,
    'Relieving Letter': null,
    'Last 3 Months Salary Slips': null,
  };
  Map<String, File?> _optionalDocs = {
    'Degree Certificate': null,
    'Passport Copy': null,
    'Driving License Copy': null,
    'Vaccination Certificate': null,
  };

  final List<String> _bloodGroups = [
    'A+',
    'A−',
    'A1+',
    'A1−',
    'A2+',
    'A2−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'A1B+',
    'A1B−',
    'A2B+',
    'A2B−',
    'O+',
    'O−',
    'Bombay phenotype (Oh/hh)',
    'Para-Bombay phenotype',
    'Unknown',
  ];

  final List<String> _bankNames = [
    'State Bank of India',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'Canara Bank',
    'Indian Bank',
    'Indian Overseas Bank',
    'Bank of Baroda',
    'Punjab National Bank',
    'Union Bank of India',
    'IDFC FIRST Bank',
    'Federal Bank',
    'City Union Bank',
    'Karur Vysya Bank',
    'Tamilnad Mercantile Bank',
  ];

  final Map<String, String> _bankIfscCodes = {
    'State Bank of India': 'SBIN',
    'HDFC Bank': 'HDFC',
    'ICICI Bank': 'ICIC',
    'Axis Bank': 'UTIB',
    'Kotak Mahindra Bank': 'KKBK',
    'Canara Bank': 'CNRB',
    'Indian Bank': 'IDIB',
    'Indian Overseas Bank': 'IOBA',
    'Bank of Baroda': 'BARB',
    'Punjab National Bank': 'PUNB',
    'Union Bank of India': 'UBIN',
    'IDFC FIRST Bank': 'IDFB',
    'Federal Bank': 'FDRL',
    'City Union Bank': 'CIUB',
    'Karur Vysya Bank': 'KVBL',
    'Tamilnad Mercantile Bank': 'TMBL',
  };

  final List<String> _cityOptions = [
    'Salem',
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Tiruchirappalli',
    'Tiruppur',
    'Erode',
    'Vellore',
    'Thoothukudi',
    'Thanjavur',
    'Dindigul',
    'Hosur',
    'Nagercoil',
    'Karur',
    'Namakkal',
    'Dharmapuri',
    'Krishnagiri',
    'Cuddalore',
    'Villupuram',
    'Kanchipuram',
  ];

  final List<String> _stateOptions = [
    'Tamil Nadu',
    'Andhra Pradesh',
    'Karnataka',
    'Kerala',
    'Telangana',
    'Maharashtra',
    'Delhi',
    'Gujarat',
    'Rajasthan',
    'Uttar Pradesh',
    'Madhya Pradesh',
    'West Bengal',
    'Odisha',
    'Punjab',
    'Haryana',
    'Bihar',
    'Assam',
    'Jharkhand',
  ];

  Map<String, String> get _cityStateMap => {
    for (final city in _cityOptions) city: 'Tamil Nadu',
  };

  final List<String> _qualificationOptions = [
    '10th',
    '12th',
    'Diploma',
    'ITI',
    'B.E',
    'B.Tech',
    'B.Sc',
    'B.Com',
    'B.A',
    'BCA',
    'M.E',
    'M.Tech',
    'M.Sc',
    'M.Com',
    'M.A',
    'MCA',
    'MBA',
    'Other',
  ];

  final List<String> _universityOptions = [
    'Anna University',
    'Periyar University',
    'Bharathiar University',
    'Bharathidasan University',
    'University of Madras',
    'SRM Institute',
    'VIT University',
    'Other',
  ];

  final Map<String, List<String>> _universityCollegeOptions = {
    'Anna University': [
      'Government College of Engineering, Salem',
      'Sona College of Technology',
      'Kongu Engineering College',
      'Sri Krishna College of Engineering and Technology',
      'PSG College of Technology',
      'Other',
    ],
    'Periyar University': [
      'Government Arts College, Salem',
      'Sona College of Arts and Science',
      'Sri Sarada College for Women',
      'Vivekanandha College of Arts and Sciences',
      'Other',
    ],
    'Bharathiar University': [
      'PSG College of Arts and Science',
      'Sri Krishna Arts and Science College',
      'Kongunadu Arts and Science College',
      'Dr. SNS Rajalakshmi College of Arts and Science',
      'Other',
    ],
    'Bharathidasan University': [
      'National College, Tiruchirappalli',
      'St. Josephs College, Tiruchirappalli',
      'Jamal Mohamed College',
      'Bishop Heber College',
      'Other',
    ],
    'University of Madras': [
      'Presidency College',
      'Loyola College',
      'Madras Christian College',
      'Ethiraj College for Women',
      'Other',
    ],
    'SRM Institute': [
      'SRM Institute of Science and Technology, Kattankulathur',
      'SRM Institute of Science and Technology, Ramapuram',
      'SRM Institute of Science and Technology, Vadapalani',
      'Other',
    ],
    'VIT University': ['VIT Vellore', 'VIT Chennai', 'Other'],
    'Other': ['Other'],
  };

  final List<String> _legacyCollegeOptions = [
    'Sona College of Technology',
    'Thiagarajar College',
    'Kongu Engineering College',
    'Government Arts College',
    'Government Engineering College',
    'Other',
  ];

  String? _verifiedIfsc;
  String? _verifiedBranch;
  bool _isIfscVerifying = false;

  List<String> get _yearOptions {
    final currentYear = DateTime.now().year;
    return List.generate(46, (index) => '${currentYear - index}');
  }

  int get _totalPages => _isExperienced ? 5 : 4;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _currentDoorCtrl.dispose();
    _currentStreetCtrl.dispose();
    _currentAddress2Ctrl.dispose();
    _currentCityCtrl.dispose();
    _currentStateCtrl.dispose();
    _permanentDoorCtrl.dispose();
    _permanentStreetCtrl.dispose();
    _permanentAddress2Ctrl.dispose();
    _permanentCityCtrl.dispose();
    _permanentStateCtrl.dispose();
    _maritalOtherCtrl.dispose();
    _nationalityCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyRelCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _aadharCtrl.dispose();
    _panCtrl.dispose();
    _passportCtrl.dispose();
    _drivingCtrl.dispose();
    _qualificationCtrl.dispose();
    _universityCtrl.dispose();
    _collegeCtrl.dispose();
    _otherCollegeCtrl.dispose();
    _yearCtrl.dispose();
    _percentageCtrl.dispose();
    _cgpaCtrl.dispose();
    _accountHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _prevCompanyCtrl.dispose();
    _prevDesignationCtrl.dispose();
    _prevExperienceCtrl.dispose();
    _prevLastDayCtrl.dispose();
    _submissionStatus.dispose();
    super.dispose();
  }

  void _nextPage() {
    final error = _currentPage == _totalPages - 1
        ? _validateAllRegistrationPages()
        : _validateRegistrationPage(_logicalPageForIndex(_currentPage));
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _submitForm();
    }
  }

  int _logicalPageForIndex(int index) {
    if (!_isExperienced && index == 3) return 4;
    return index;
  }

  String? _validateAllRegistrationPages() {
    final pages = <int>[0, 1, 2, if (_isExperienced) 3, 4];
    for (final page in pages) {
      final error = _validateRegistrationPage(page);
      if (error != null) return error;
    }
    return null;
  }

  String? _validateRegistrationPage(int page) {
    String value(TextEditingController controller) => controller.text.trim();
    bool isName(String text) =>
        RegExp(r"^[A-Za-z][A-Za-z .'-]{1,79}$").hasMatch(text);

    if (page == 0) {
      if (!isName(value(_firstNameCtrl))) return 'Enter a valid first name.';
      if (!isName(value(_lastNameCtrl))) return 'Enter a valid last name.';
      final dob = _parseRegistrationDate(value(_dobCtrl));
      if (dob == null) return 'Select a valid date of birth.';
      final today = DateTime.now();
      var age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      if (age < 18) return 'Employee must be at least 18 years old.';
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value(_mobileCtrl))) {
        return 'Enter a valid 10-digit Indian mobile number.';
      }
      if (!RegExp(
        r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
      ).hasMatch(value(_emailCtrl))) {
        return 'Enter a valid personal email address.';
      }
      if (value(_currentDoorCtrl).isEmpty ||
          value(_currentStreetCtrl).isEmpty ||
          value(_currentAddress2Ctrl).isEmpty ||
          value(_currentCityCtrl).isEmpty ||
          value(_currentStateCtrl).isEmpty) {
        return 'Complete the current address.';
      }
      if (value(_permanentDoorCtrl).isEmpty ||
          value(_permanentStreetCtrl).isEmpty ||
          value(_permanentAddress2Ctrl).isEmpty ||
          value(_permanentCityCtrl).isEmpty ||
          value(_permanentStateCtrl).isEmpty) {
        return 'Complete the permanent address.';
      }
      if (_maritalStatus == 'other' && value(_maritalOtherCtrl).isEmpty) {
        return 'Enter the marital status.';
      }
      if (value(_nationalityCtrl).isEmpty) return 'Enter nationality.';
    }

    if (page == 1) {
      if (!isName(value(_emergencyNameCtrl))) {
        return 'Enter a valid emergency contact name.';
      }
      if (value(_emergencyRelCtrl).length < 2) {
        return 'Enter the emergency contact relationship.';
      }
      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value(_emergencyContactCtrl))) {
        return 'Enter a valid emergency mobile number.';
      }
      if (!RegExp(r'^\d{12}$').hasMatch(value(_aadharCtrl))) {
        return 'Aadhaar number must contain exactly 12 digits.';
      }
      if (!RegExp(
        r'^[A-Z]{5}[0-9]{4}[A-Z]$',
      ).hasMatch(value(_panCtrl).toUpperCase())) {
        return 'Enter a valid PAN number, for example ABCDE1234F.';
      }
      final passport = value(_passportCtrl).toUpperCase();
      if (passport.isNotEmpty &&
          !RegExp(r'^[A-Z][0-9]{7}$').hasMatch(passport)) {
        return 'Enter a valid passport number or leave it blank.';
      }
      final driving = value(_drivingCtrl).toUpperCase();
      if (driving.isNotEmpty &&
          !RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{7,13}$').hasMatch(driving)) {
        return 'Enter a valid driving licence number or leave it blank.';
      }
    }

    if (page == 2) {
      if (value(_qualificationCtrl).isEmpty) return 'Select qualification.';
      if (value(_universityCtrl).isEmpty) return 'Select university.';
      if (_selectedCollegeName.isEmpty) return 'Select or enter college name.';
      final year = int.tryParse(value(_yearCtrl));
      final currentYear = DateTime.now().year;
      if (year == null || year < 1950 || year > currentYear) {
        return 'Select a valid year of passing.';
      }
      final percentage = double.tryParse(value(_percentageCtrl));
      if (percentage == null || percentage < 0 || percentage > 100) {
        return 'Percentage must be between 0 and 100.';
      }
      final cgpa = double.tryParse(value(_cgpaCtrl));
      if (cgpa == null || cgpa < 0 || cgpa > 10) {
        return 'CGPA must be between 0 and 10.';
      }
      if (!isName(value(_accountHolderCtrl))) {
        return 'Enter a valid account holder name.';
      }
      if (value(_bankNameCtrl).isEmpty) return 'Select bank name.';
      if (!RegExp(r'^\d{9,18}$').hasMatch(value(_accountNumberCtrl))) {
        return 'Bank account number must contain 9 to 18 digits.';
      }
      final ifsc = value(_ifscCtrl).toUpperCase();
      if (!_isValidIfsc(ifsc)) return 'Enter a valid 11-character IFSC code.';
      if (_verifiedIfsc != ifsc) {
        return 'Verify IFSC using the live bank registry.';
      }
      if (value(_branchCtrl).length < 2) return 'Enter the bank branch name.';
      if (_verifiedBranch != value(_branchCtrl)) {
        return 'Branch details changed. Verify IFSC again.';
      }
    }

    if (page == 3) {
      if (value(_prevCompanyCtrl).length < 2) {
        return 'Enter the previous company name.';
      }
      if (value(_prevDesignationCtrl).length < 2) {
        return 'Enter the previous designation.';
      }
      final experience = double.tryParse(value(_prevExperienceCtrl));
      if (experience == null || experience <= 0 || experience > 60) {
        return 'Experience must be greater than 0 and not more than 60 years.';
      }
      if (_parseRegistrationDate(value(_prevLastDayCtrl)) == null) {
        return 'Select a valid last working day.';
      }
    }

    if (page == 4) {
      final missingMandatory = _mandatoryDocs.entries
          .where((entry) => entry.value == null)
          .map((entry) => entry.key)
          .toList();
      if (missingMandatory.isNotEmpty) {
        return 'Upload required document: ${missingMandatory.first}.';
      }
      final missingEducation = _educationDocs.entries
          .where((entry) => entry.value == null)
          .map((entry) => entry.key)
          .toList();
      if (missingEducation.isNotEmpty) {
        return 'Upload education document: ${missingEducation.first}.';
      }
      if (_isExperienced) {
        final missingExperience = _experiencedDocs.entries
            .where((entry) => entry.value == null)
            .map((entry) => entry.key)
            .toList();
        if (missingExperience.isNotEmpty) {
          return 'Upload experience document: ${missingExperience.first}.';
        }
      }
    }
    return null;
  }

  DateTime? _parseRegistrationDate(String input) {
    final parts = input.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showSeparatedDatePicker(
      context: context,
      initialDate: DateTime(now.year - 22),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: ThemeConfig.blueAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickFile(Map<String, File?> docMap, String key) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 72,
    );
    if (picked == null || !mounted) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: ThemeConfig.blueAccent,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Document'),
      ],
    );
    if (!mounted) return;
    setState(() => docMap[key] = File(cropped?.path ?? picked.path));
  }

  bool _isValidIfsc(String value) {
    return RegExp(
      r'^[A-Z]{4}0[A-Z0-9]{6}$',
    ).hasMatch(value.trim().toUpperCase());
  }

  String? _ifscValidator(String? value) {
    final ifsc = (value ?? '').trim().toUpperCase();
    if (ifsc.isEmpty) return 'Required';
    if (!_isValidIfsc(ifsc)) return 'Use format ABCD0XXXXXX';
    return null;
  }

  Future<void> _verifyIfscLive() async {
    final ifsc = _ifscCtrl.text.trim().toUpperCase();
    if (!_isValidIfsc(ifsc)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 11-character IFSC code.')),
      );
      return;
    }
    setState(() => _isIfscVerifying = true);
    try {
      final response = await http
          .get(
            ApiConfig.uri(
              '/verify-ifsc/?ifsc=${Uri.encodeQueryComponent(ifsc)}',
            ),
          )
          .timeout(const Duration(seconds: 12));
      final body = jsonDecode(response.body);
      final data = body is Map
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{};
      if (response.statusCode != 200 || data['verified'] != true) {
        throw Exception(data['message'] ?? 'IFSC could not be verified.');
      }
      final selectedCode = _bankIfscCodes[_bankNameCtrl.text.trim()];
      if (selectedCode != null && !ifsc.startsWith(selectedCode)) {
        throw Exception(
          'This IFSC belongs to ${data['bank']}, not the selected bank.',
        );
      }
      final branch = '${data['branch'] ?? ''}'.trim();
      if (branch.isEmpty) {
        throw Exception('The live registry did not return a branch name.');
      }
      if (!mounted) return;
      setState(() {
        _ifscCtrl.text = ifsc;
        _branchCtrl.text = branch;
        _verifiedIfsc = ifsc;
        _verifiedBranch = branch;
      });
      final location = [
        '${data['city'] ?? ''}'.trim(),
        '${data['state'] ?? ''}'.trim(),
      ].where((value) => value.isNotEmpty).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            'Verified: ${data['bank']} • $branch'
            '${location.isEmpty ? '' : ' • $location'}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _verifiedIfsc = null;
        _verifiedBranch = null;
      });
      final message = '$error'.replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.redAccent, content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isIfscVerifying = false);
    }
  }

  List<String> get _collegeOptionsForUniversity {
    final university = _universityCtrl.text.trim();
    return _universityCollegeOptions[university] ?? _legacyCollegeOptions;
  }

  String get _selectedCollegeName {
    if (_collegeCtrl.text.trim() == 'Other') {
      return _otherCollegeCtrl.text.trim();
    }
    return _collegeCtrl.text.trim();
  }

  void _setUniversity(String university) {
    _universityCtrl.text = university;
    _collegeCtrl.clear();
    _otherCollegeCtrl.clear();
    if (university == 'Other') {
      _collegeCtrl.text = 'Other';
    }
  }

  void _setCollege(String college) {
    _collegeCtrl.text = college;
    if (college != 'Other') {
      _otherCollegeCtrl.clear();
    }
  }

  void _setScoreText(TextEditingController controller, String value) {
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  String _formatScore(double value, {int decimals = 2}) {
    final fixed = value.toStringAsFixed(decimals);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _syncCgpaFromPercentage(String value) {
    if (_isSyncingScores) return;
    final percentage = double.tryParse(value.trim());
    _isSyncingScores = true;
    if (percentage == null) {
      _cgpaCtrl.clear();
    } else {
      final bounded = percentage.clamp(0, 100).toDouble();
      _setScoreText(_cgpaCtrl, _formatScore(bounded / 9.5));
    }
    _isSyncingScores = false;
  }

  void _syncPercentageFromCgpa(String value) {
    if (_isSyncingScores) return;
    final cgpa = double.tryParse(value.trim());
    _isSyncingScores = true;
    if (cgpa == null) {
      _percentageCtrl.clear();
    } else {
      final bounded = cgpa.clamp(0, 10).toDouble();
      _setScoreText(_percentageCtrl, _formatScore(bounded * 9.5));
    }
    _isSyncingScores = false;
  }

  void _setCurrentState(String state) {
    setState(() {
      _currentStateCtrl.text = state;
      if (!indiaCitiesForState(state).contains(_currentCityCtrl.text)) {
        _currentCityCtrl.clear();
      }
      if (_sameAsCurrent) {
        _permanentStateCtrl.text = state;
        _permanentCityCtrl.text = _currentCityCtrl.text;
      }
    });
  }

  void _setCurrentCity(String city) {
    setState(() {
      _currentCityCtrl.text = city;
      if (_sameAsCurrent) _permanentCityCtrl.text = city;
    });
  }

  void _setPermanentState(String state) {
    setState(() {
      _permanentStateCtrl.text = state;
      if (!indiaCitiesForState(state).contains(_permanentCityCtrl.text)) {
        _permanentCityCtrl.clear();
      }
    });
  }

  void _setPermanentCity(String city) {
    setState(() => _permanentCityCtrl.text = city);
  }

  void _viewFile(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FileViewerPage(file: file)),
    );
  }

  Future<void> _ensureBackendReady() async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await http
            .get(ApiConfig.uri('/health/'))
            .timeout(const Duration(seconds: 60));
        if (response.statusCode >= 200 && response.statusCode < 300) return;
        lastError = 'HTTP ${response.statusCode}';
      } catch (error) {
        lastError = error;
      }
      if (attempt < 2) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    throw http.ClientException(
      'Backend did not become ready after 3 attempts: $lastError',
      ApiConfig.uri('/health/'),
    );
  }

  void _showSubmissionPopup() {
    if (_submissionPopupVisible) return;
    _submissionPopupVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AppSubmissionProgressDialog(status: _submissionStatus),
      ).whenComplete(() => _submissionPopupVisible = false),
    );
  }

  void _closeSubmissionPopup() {
    if (!_submissionPopupVisible || !mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _submissionPopupVisible = false;
  }

  Future<void> _submitForm() async {
    final nationality = _nationalityCtrl.text.trim();
    if (nationality.isEmpty) {
      _nationalityCtrl.text = 'Indian';
    }
    setState(() => _isLoading = true);
    _submissionStatus.value = 'Connecting securely to the HRMS server...';
    _showSubmissionPopup();
    await Future<void>.delayed(Duration.zero);
    try {
      // Wake a sleeping Render instance before opening a large multipart
      // upload. This prevents the first submission from failing during cold
      // start while keeping every selected local document available to retry.
      await _ensureBackendReady();
      _submissionStatus.value = 'Preparing your selected documents...';
      final uri = ApiConfig.uri('/register-employee/');

      // Text fields
      final registrationFields = <String, String>{
        'submission_key': _submissionKey,
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
        'college': _selectedCollegeName,
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
      };

      // Document files
      final allDocs = {
        'doc_passport_photo': _mandatoryDocs['Passport Size Photo'],
        'doc_aadhar': _mandatoryDocs['Aadhaar Card Copy'],
        'doc_pan': _mandatoryDocs['PAN Card Copy'],
        'doc_bank_passbook':
            _mandatoryDocs['Bank Passbook / Cancelled Cheque Copy'],
        'doc_10th': _educationDocs['10th Marksheet'],
        'doc_12th': _educationDocs['12th Marksheet / Diploma Certificate'],
        'doc_consolidated': _educationDocs['Consolidated Marksheet'],
        'doc_degree': _optionalDocs['Degree Certificate'],
        'doc_college_noc': _educationDocs['NOC Certificate from College'],
        'doc_resume': _experiencedDocs['Resume/CV'],
        'doc_experience_cert': _experiencedDocs['Experience Certificate'],
        'doc_relieving': _experiencedDocs['Relieving Letter'],
        'doc_salary_slips': _experiencedDocs['Last 3 Months Salary Slips'],
        'doc_passport_copy': _optionalDocs['Passport Copy'],
        'doc_driving': _optionalDocs['Driving License Copy'],
        'doc_vaccination': _optionalDocs['Vaccination Certificate'],
      };

      var totalUploadBytes = 0;
      for (final file in allDocs.values.whereType<File>()) {
        totalUploadBytes += await file.length();
      }
      if (totalUploadBytes > _maxUploadBytes) {
        final sizeMb = (totalUploadBytes / (1024 * 1024)).toStringAsFixed(1);
        throw FileSystemException(
          'Selected documents total $sizeMb MB. Please reselect smaller images '
          '(maximum 25 MB in total).',
        );
      }
      final documentCount = allDocs.values.whereType<File>().length;

      Future<http.Response> sendUpload() async {
        final request = http.MultipartRequest('POST', uri)
          ..fields.addAll(registrationFields);
        for (final entry in allDocs.entries) {
          if (entry.value != null) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value!.path),
            );
          }
        }
        final streamed = await request.send().timeout(
          const Duration(minutes: 5),
        );
        return http.Response.fromStream(streamed);
      }

      http.Response? response;
      Object? lastUploadError;
      for (var attempt = 0; attempt < 3; attempt++) {
        _submissionStatus.value = attempt == 0
            ? 'Uploading $documentCount documents securely...'
            : 'Connection interrupted. Retrying automatically (${attempt + 1}/3)...';
        try {
          final candidate = await sendUpload();
          if ({502, 503, 504}.contains(candidate.statusCode) && attempt < 2) {
            lastUploadError = 'HTTP ${candidate.statusCode}';
          } else {
            response = candidate;
            break;
          }
        } catch (error) {
          lastUploadError = error;
          if (attempt == 2) rethrow;
        }
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
      if (response == null) {
        throw http.ClientException(
          'Upload failed after automatic retries: $lastUploadError',
          uri,
        );
      }
      _submissionStatus.value = 'Finalizing your registration...';
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Unexpected response format');
        }
        data = decoded;
      } on FormatException {
        throw http.ClientException(
          'Server returned HTTP ${response.statusCode} instead of JSON.',
          uri,
        );
      }

      if (!mounted) return;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['success'] == true) {
        _closeSubmissionPopup();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: ThemeConfig.getCardBg(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF43E97B),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Submitted!',
                  style: TextStyle(
                    color: ThemeConfig.getTextPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Registration submitted!\nHR team will contact you soon.',
              style: TextStyle(color: ThemeConfig.getTextSecondary(context)),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFF4FACFE),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        final errorMessage = _registrationErrorMessage(data['errors']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      _closeSubmissionPopup();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Upload timed out. Check your connection and try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on SocketException catch (e) {
      if (!mounted) return;
      _closeSubmissionPopup();
      final wasAborted = e.message.toLowerCase().contains('connection abort');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasAborted
                ? 'The server closed the upload. Reselect the documents to '
                      'reduce their size, then try again.'
                : 'Network error: ${e.message}. Please check Wi-Fi or mobile data.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on FileSystemException catch (e) {
      if (!mounted) return;
      _closeSubmissionPopup();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } on http.ClientException catch (e) {
      if (!mounted) return;
      _closeSubmissionPopup();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      if (!mounted) return;
      _closeSubmissionPopup();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      _closeSubmissionPopup();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _registrationErrorMessage(dynamic errors) {
    if (errors is Map && errors.isNotEmpty) {
      final entry = errors.entries.first;
      final label = entry.key
          .toString()
          .replaceAll('_', ' ')
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
          .join(' ');
      final value = entry.value;
      final message = value is List && value.isNotEmpty
          ? value.first.toString()
          : value.toString();
      return '$label: $message';
    }
    return errors?.toString() ?? 'Registration could not be submitted.';
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
      if (_isExperienced)
        _buildPage4(isDark, textPrimary, textSecondary, cardBg, cardBorder),
      _buildPage5(textPrimary, textSecondary, cardBg, cardBorder),
    ];

    final pageLabels = [
      'Personal',
      'Identity',
      'Education & Bank',
      if (_isExperienced) 'Experience',
      'Documents',
    ];

    return Scaffold(
      body: ConstellationBackground(
        accentColor: ThemeConfig.blueAccent,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _currentPage > 0
                          ? _prevPage
                          : () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: textPrimary,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Registration',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Step ${_currentPage + 1} of ${pages.length} • ${pageLabels[_currentPage]}',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    pages.length,
                    (i) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: i <= _currentPage
                              ? ThemeConfig.blueAccent
                              : cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
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
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: ThemeConfig.blueGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _currentPage == pages.length - 1
                                  ? 'Submit Registration'
                                  : 'Next',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildPage1(
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color cardBorder,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Personal Details', tp),
          _card(cardBg, cardBorder, [
            _row([
              _field(
                'First Name *',
                _firstNameCtrl,
                isDark,
                tp,
                ts,
                cardBorder,
              ),
              _field('Last Name *', _lastNameCtrl, isDark, tp, ts, cardBorder),
            ]),
            const SizedBox(height: 14),
            _label('Gender *', ts),
            Row(
              children: ['male', 'female', 'other']
                  .map(
                    (g) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _gender = g),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: _gender == g
                                ? ThemeConfig.blueGradient
                                : null,
                            color: _gender == g ? null : cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _gender == g
                                  ? ThemeConfig.loginButtonColor
                                  : cardBorder,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              g[0].toUpperCase() + g.substring(1),
                              style: TextStyle(
                                color: _gender == g ? Colors.white : tp,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            _label('Date of Birth *', ts),
            _dateField('DD/MM/YYYY', _dobCtrl, isDark, tp, ts, cardBorder),
            const SizedBox(height: 14),
            _label('Mobile Number * (10 digits)', ts),
            _textField(
              'Mobile',
              _mobileCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              keyboard: TextInputType.phone,
              maxLen: 10,
            ),
            const SizedBox(height: 14),
            _field(
              'Personal Email ID *',
              _emailCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _label('Current Address *', ts),
            _field('Door No *', _currentDoorCtrl, isDark, tp, ts, cardBorder),
            const SizedBox(height: 10),
            _field(
              'Street Name *',
              _currentStreetCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 10),
            _field(
              'Area / Landmark *',
              _currentAddress2Ctrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 10),
            _row([
              _addressDropdown(
                'State *',
                _currentStateCtrl,
                indiaStates,
                isDark,
                tp,
                ts,
                cardBg,
                cardBorder,
                onChanged: _setCurrentState,
              ),
              _addressDropdown(
                'City *',
                _currentCityCtrl,
                indiaCitiesForState(_currentStateCtrl.text),
                isDark,
                tp,
                ts,
                cardBg,
                cardBorder,
                enabled: _currentStateCtrl.text.isNotEmpty,
                onChanged: _setCurrentCity,
              ),
            ]),
            const SizedBox(height: 10),
            Row(
              children: [
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
                Text(
                  'Same as Current Address',
                  style: TextStyle(color: ts, fontSize: 12),
                ),
              ],
            ),
            _label('Permanent Address *', ts),
            _field('Door No *', _permanentDoorCtrl, isDark, tp, ts, cardBorder),
            const SizedBox(height: 10),
            _field(
              'Street Name *',
              _permanentStreetCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 10),
            _field(
              'Area / Landmark *',
              _permanentAddress2Ctrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 10),
            _row([
              _addressDropdown(
                'State *',
                _permanentStateCtrl,
                indiaStates,
                isDark,
                tp,
                ts,
                cardBg,
                cardBorder,
                enabled: !_sameAsCurrent,
                onChanged: _setPermanentState,
              ),
              _addressDropdown(
                'City *',
                _permanentCityCtrl,
                indiaCitiesForState(_permanentStateCtrl.text),
                isDark,
                tp,
                ts,
                cardBg,
                cardBorder,
                enabled: !_sameAsCurrent,
                onChanged: _setPermanentCity,
              ),
            ]),
            const SizedBox(height: 14),
            _label('Marital Status *', ts),
            _dropdown(
              _maritalStatus,
              ['single', 'married', 'other'],
              (v) => setState(() => _maritalStatus = v!),
              isDark,
              tp,
              cardBg,
              cardBorder,
            ),
            if (_maritalStatus == 'other') ...[
              const SizedBox(height: 10),
              _field(
                'Specify Marital Status *',
                _maritalOtherCtrl,
                isDark,
                tp,
                ts,
                cardBorder,
              ),
            ],
            const SizedBox(height: 14),
            _label('Blood Group *', ts),
            _dropdown(
              _bloodGroup,
              _bloodGroups,
              (v) => setState(() => _bloodGroup = v!),
              isDark,
              tp,
              cardBg,
              cardBorder,
              showScrollbar: true,
            ),
            const SizedBox(height: 14),
            _nationalityField(isDark, tp, ts, cardBorder),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPage2(
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color cardBorder,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Emergency Contact', tp),
          _card(cardBg, cardBorder, [
            _field(
              'Emergency Contact Name *',
              _emergencyNameCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 14),
            _field(
              'Relationship *',
              _emergencyRelCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 14),
            _label('Contact Number * (10 digits)', ts),
            _textField(
              'Contact Number',
              _emergencyContactCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              keyboard: TextInputType.phone,
              maxLen: 10,
            ),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Employee Identity Details', tp),
          _card(cardBg, cardBorder, [
            _label('Aadhaar Number * (12 digits)', ts),
            _textField(
              'Aadhaar Number',
              _aadharCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              keyboard: TextInputType.number,
              maxLen: 12,
            ),
            const SizedBox(height: 14),
            _label('PAN Number * (e.g. ABCDE1234F)', ts),
            _textField(
              'PAN Number',
              _panCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              isUpperCase: true,
              maxLen: 10,
            ),
            const SizedBox(height: 14),
            _field(
              'Passport Number (Optional)',
              _passportCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              required: false,
            ),
            const SizedBox(height: 14),
            _field(
              'Driving License Number (Optional)',
              _drivingCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              required: false,
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPage3(
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color cardBorder,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Educational Details', tp),
          _card(cardBg, cardBorder, [
            _addressDropdown(
              'Qualification *',
              _qualificationCtrl,
              _qualificationOptions,
              isDark,
              tp,
              ts,
              cardBg,
              cardBorder,
            ),
            const SizedBox(height: 14),
            _addressDropdown(
              'University *',
              _universityCtrl,
              _universityOptions,
              isDark,
              tp,
              ts,
              cardBg,
              cardBorder,
              onChanged: _setUniversity,
            ),
            const SizedBox(height: 14),
            _addressDropdown(
              'College Name *',
              _collegeCtrl,
              _collegeOptionsForUniversity,
              isDark,
              tp,
              ts,
              cardBg,
              cardBorder,
              enabled: _universityCtrl.text.trim().isNotEmpty,
              onChanged: _setCollege,
            ),
            if (_collegeCtrl.text.trim() == 'Other') ...[
              const SizedBox(height: 14),
              _field(
                'Enter your college name *',
                _otherCollegeCtrl,
                isDark,
                tp,
                ts,
                cardBorder,
              ),
            ],
            const SizedBox(height: 14),
            _row([
              _addressDropdown(
                'Year of Passing *',
                _yearCtrl,
                _yearOptions,
                isDark,
                tp,
                ts,
                cardBg,
                cardBorder,
              ),
              _scoreField(
                'Percentage *',
                _percentageCtrl,
                isDark,
                tp,
                ts,
                cardBorder,
                hint: 'e.g. 85',
                suffix: '%',
                maxValue: 100,
                onChanged: _syncCgpaFromPercentage,
              ),
            ]),
            const SizedBox(height: 14),
            _scoreField(
              'CGPA *',
              _cgpaCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              hint: 'e.g. 8.95',
              maxValue: 10,
              onChanged: _syncPercentageFromCgpa,
            ),
            const SizedBox(height: 4),
            Text(
              'Percentage and CGPA are auto-calculated from each other.',
              style: TextStyle(
                color: ts,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Bank Details', tp),
          _card(cardBg, cardBorder, [
            _bankTextField(
              'Account Holder Name *',
              'Enter account holder name',
              _accountHolderCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _bankDropdown(
              'Bank Name *',
              'Enter bank name',
              isDark,
              tp,
              ts,
              cardBg,
              cardBorder,
            ),
            const SizedBox(height: 14),
            _bankTextField(
              'Account Number *',
              'Enter account number',
              _accountNumberCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              Icons.credit_card_rounded,
              keyboard: TextInputType.number,
              obscureText: !_showAccountNumber,
              suffix: IconButton(
                icon: Icon(
                  _showAccountNumber
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showAccountNumber = !_showAccountNumber);
                },
              ),
            ),
            const SizedBox(height: 14),
            _bankTextField(
              'IFSC Code *',
              'Enter IFSC code',
              _ifscCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              Icons.verified_user_outlined,
              isUpperCase: true,
              maxLen: 11,
              validator: _ifscValidator,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (value) {
                final upper = value.trim().toUpperCase();
                if (upper != _verifiedIfsc) {
                  setState(() {
                    _verifiedIfsc = null;
                    _verifiedBranch = null;
                    _branchCtrl.clear();
                  });
                }
              },
              suffix: _ifscVerifyButton(cardBorder),
            ),
            const SizedBox(height: 14),
            _bankTextField(
              'Branch Name *',
              'Enter branch name',
              _branchCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              Icons.location_on_outlined,
              onChanged: (_) => setState(() => _verifiedBranch = null),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionTitle('Employment Type', tp),
          _card(cardBg, cardBorder, [
            Text(
              'Are you a fresher or experienced?',
              style: TextStyle(
                color: ts,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExperienced = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: !_isExperienced
                            ? ThemeConfig.blueGradient
                            : null,
                        color: !_isExperienced ? null : cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !_isExperienced
                              ? ThemeConfig.loginButtonColor
                              : cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Fresher',
                          style: TextStyle(
                            color: !_isExperienced ? Colors.white : tp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isExperienced = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: _isExperienced
                            ? ThemeConfig.blueGradient
                            : null,
                        color: _isExperienced ? null : cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isExperienced
                              ? ThemeConfig.loginButtonColor
                              : cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Experienced',
                          style: TextStyle(
                            color: _isExperienced ? Colors.white : tp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPage4(
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color cardBorder,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Previous Employment', tp),
          _card(cardBg, cardBorder, [
            _field(
              'Previous Company Name *',
              _prevCompanyCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 14),
            _field(
              'Designation *',
              _prevDesignationCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
            const SizedBox(height: 14),
            _textField(
              'Experience (Years) *',
              _prevExperienceCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _label('Last Working Day *', ts),
            _dateField(
              'DD/MM/YYYY',
              _prevLastDayCtrl,
              isDark,
              tp,
              ts,
              cardBorder,
            ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPage5(Color tp, Color ts, Color cardBg, Color cardBorder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Documents Required', tp),
          _docSection(
            'Mandatory Documents',
            _mandatoryDocs,
            tp,
            ts,
            cardBg,
            cardBorder,
          ),
          const SizedBox(height: 16),
          _docSection(
            'Educational Documents',
            _educationDocs,
            tp,
            ts,
            cardBg,
            cardBorder,
          ),
          if (_isExperienced) ...[
            const SizedBox(height: 16),
            _docSection(
              'Experienced Employees',
              _experiencedDocs,
              tp,
              ts,
              cardBg,
              cardBorder,
            ),
          ],
          const SizedBox(height: 16),
          _docSection(
            'Optional Documents',
            _optionalDocs,
            tp,
            ts,
            cardBg,
            cardBorder,
            optional: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _docSection(
    String title,
    Map<String, File?> docs,
    Color tp,
    Color ts,
    Color cardBg,
    Color cardBorder, {
    bool optional = false,
  }) {
    return _card(cardBg, cardBorder, [
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ...docs.keys.map((doc) {
        final file = docs[doc];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc,
                style: TextStyle(
                  color: ts,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Upload Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickFile(docs, doc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: file != null
                              ? const Color(0xFF43E97B).withAlpha(20)
                              : ThemeConfig.blueAccent.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: file != null
                                ? const Color(0xFF43E97B)
                                : ThemeConfig.blueAccent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              file != null
                                  ? Icons.check_circle_rounded
                                  : Icons.upload_rounded,
                              color: file != null
                                  ? const Color(0xFF43E97B)
                                  : ThemeConfig.blueAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              file != null ? 'Uploaded ✅' : 'Upload Document',
                              style: TextStyle(
                                color: file != null
                                    ? const Color(0xFF43E97B)
                                    : ThemeConfig.blueAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // View Button — only show if uploaded
                  if (file != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _viewFile(file),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
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
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'View',
                              style: TextStyle(
                                color: Color(0xFF4FACFE),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (file != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '📎 ${file.path.split('/').last}',
                    style: const TextStyle(
                      color: Color(0xFF43E97B),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    ]);
  }

  // Helper Widgets
  Widget _sectionTitle(String t, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      t,
      style: TextStyle(color: c, fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _card(Color bg, Color border, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _row(List<Widget> children) => Row(
    children: children
        .map(
          (w) => Expanded(
            child: Padding(padding: const EdgeInsets.only(right: 8), child: w),
          ),
        )
        .toList(),
  );

  Widget _label(String t, Color ts) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: TextStyle(color: ts, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl,
    bool isDark,
    Color tp,
    Color ts,
    Color cb, {
    TextInputType keyboard = TextInputType.text,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ts,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          style: TextStyle(color: tp, fontSize: 13),
          validator: required
              ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
              : null,
          decoration: _inputDec(label, isDark, cb),
        ),
      ],
    );
  }

  Widget _nationalityField(bool isDark, Color tp, Color ts, Color cb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nationality *',
          style: TextStyle(
            color: ts,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _nationalityCtrl.text),
          displayStringForOption: (option) => option,
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return nationalityOptions.take(12);
            return nationalityOptions
                .where((option) => option.toLowerCase().contains(query))
                .take(12);
          },
          onSelected: (option) => _nationalityCtrl.text = option,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              style: TextStyle(color: tp, fontSize: 13),
              onChanged: (value) => _nationalityCtrl.text = value,
              validator: (value) {
                final nationality = (value ?? '').trim();
                if (nationality.isEmpty) return 'Required';
                if (!nationalityOptions.contains(nationality)) {
                  return 'Select a nationality from the list';
                }
                return null;
              },
              decoration: _inputDec(
                'Search nationality',
                isDark,
                cb,
              ).copyWith(suffixIcon: Icon(Icons.arrow_drop_down, color: ts)),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final values = options.toList();
            final scrollController = ScrollController();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                color: isDark ? const Color(0xFF0A1728) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 260,
                    maxWidth: 580,
                  ),
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: values.length > 4,
                    trackVisibility: values.length > 4,
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: values.length,
                      itemBuilder: (context, index) => ListTile(
                        dense: true,
                        title: Text(
                          values[index],
                          style: TextStyle(color: tp, fontSize: 13),
                        ),
                        onTap: () => onSelected(values[index]),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _scoreField(
    String label,
    TextEditingController ctrl,
    bool isDark,
    Color tp,
    Color ts,
    Color cb, {
    required String hint,
    required double maxValue,
    String? suffix,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ts,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: TextStyle(color: tp, fontSize: 13),
          onChanged: onChanged,
          validator: (value) {
            final score = double.tryParse((value ?? '').trim());
            if (score == null) return 'Required';
            if (score < 0 || score > maxValue) {
              return 'Enter 0 to ${_formatScore(maxValue, decimals: 0)}';
            }
            return null;
          },
          decoration: _inputDec(hint, isDark, cb).copyWith(
            suffixText: suffix,
            suffixStyle: TextStyle(
              color: ts,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressDropdown(
    String label,
    TextEditingController ctrl,
    List<String> items,
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color cb, {
    bool enabled = true,
    ValueChanged<String>? onChanged,
  }) {
    final value = items.contains(ctrl.text) ? ctrl.text : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ts,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AppDropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 240,
          showScrollbar: items.length > 4,
          dropdownColor: cardBg,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
          ),
          style: TextStyle(
            color: tp,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          hint: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 12),
            ),
          ),
          selectedItemBuilder: (context) => items.map((item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: enabled ? tp : ts,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          decoration: _inputDec(label, isDark, cb).copyWith(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 36,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          color: tp,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value == null) return;
                  setState(() {
                    ctrl.text = value;
                    onChanged?.call(value);
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl,
    bool isDark,
    Color tp,
    Color ts,
    Color cb, {
    TextInputType keyboard = TextInputType.text,
    int? maxLen,
    bool isUpperCase = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: ts,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLength: maxLen,
          textCapitalization: isUpperCase
              ? TextCapitalization.characters
              : TextCapitalization.none,
          style: TextStyle(color: tp, fontSize: 13),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          decoration: _inputDec(label, isDark, cb).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _bankTextField(
    String label,
    String hint,
    TextEditingController ctrl,
    bool isDark,
    Color tp,
    Color ts,
    Color cb,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int? maxLen,
    bool isUpperCase = false,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, ts),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLength: maxLen,
          obscureText: obscureText,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          textCapitalization: isUpperCase
              ? TextCapitalization.characters
              : TextCapitalization.words,
          style: TextStyle(color: tp, fontSize: 13),
          validator:
              validator ??
              (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          decoration: _bankInputDec(
            hint,
            isDark,
            cb,
            icon,
            suffix: suffix,
          ).copyWith(counterText: ''),
        ),
      ],
    );
  }

  Widget _bankDropdown(
    String label,
    String hint,
    bool isDark,
    Color tp,
    Color ts,
    Color cardBg,
    Color cb,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, ts),
        AppDropdownButtonFormField<String>(
          value: _bankNameCtrl.text.isEmpty ? null : _bankNameCtrl.text,
          isExpanded: true,
          menuMaxHeight: 240,
          showScrollbar: true,
          dropdownColor: cardBg,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
          ),
          style: TextStyle(color: tp, fontSize: 13),
          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 12),
          ),
          decoration: _bankInputDec(
            hint,
            isDark,
            cb,
            Icons.account_balance_rounded,
          ),
          items: _bankNames
              .map(
                (bank) => DropdownMenuItem(
                  value: bank,
                  child: Text(bank, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _bankNameCtrl.text = value;
              _verifiedIfsc = null;
              _verifiedBranch = null;
              _branchCtrl.clear();
            });
          },
        ),
      ],
    );
  }

  InputDecoration _bankInputDec(
    String hint,
    bool isDark,
    Color cb,
    IconData icon, {
    Widget? suffix,
  }) {
    return _inputDec(hint, isDark, cb).copyWith(
      prefixIcon: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF0D3769).withAlpha(150),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: Colors.white70, size: 20),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 58, minHeight: 52),
      suffixIcon: suffix,
    );
  }

  Widget _ifscVerifyButton(Color cb) {
    return Container(
      width: 78,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: cb)),
      ),
      child: TextButton(
        onPressed: _isIfscVerifying ? null : _verifyIfscLive,
        child: _isIfscVerifying
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _verifiedIfsc == _ifscCtrl.text.trim().toUpperCase()
                    ? 'Verified'
                    : 'Verify',
                style: TextStyle(
                  color: _verifiedIfsc == _ifscCtrl.text.trim().toUpperCase()
                      ? Colors.greenAccent
                      : ThemeConfig.blueAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Widget _dateField(
    String hint,
    TextEditingController ctrl,
    bool isDark,
    Color tp,
    Color ts,
    Color cb,
  ) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: () => _pickDate(ctrl),
      style: TextStyle(color: tp, fontSize: 13),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: _inputDec(hint, isDark, cb).copyWith(
        suffixIcon: const Icon(
          Icons.calendar_month_outlined,
          color: Color(0xFF4FACFE),
          size: 18,
        ),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    bool isDark,
    Color tp,
    Color cardBg,
    Color cb, {
    bool showScrollbar = false,
  }) {
    return AppDropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      menuMaxHeight: 240,
      showScrollbar: showScrollbar || items.length > 4,
      dropdownColor: cardBg,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Colors.white70,
      ),
      style: TextStyle(color: tp, fontSize: 13, fontWeight: FontWeight.w600),
      selectedItemBuilder: (context) => items.map((item) {
        final label = item[0].toUpperCase() + item.substring(1);
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: tp,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
      items: items.map((item) {
        final label = item[0].toUpperCase() + item.substring(1);
        return DropdownMenuItem<String>(
          value: item,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            height: 36,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: tp,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: _inputDec('', isDark, cb).copyWith(
        hintText: null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, bool isDark, Color cb) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withAlpha(100), fontSize: 12),
        filled: true,
        fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cb),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cb),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
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
        title: Text(
          file.path.split('/').last,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Document saved!'))),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insert_drive_file_rounded,
                    color: Colors.white54,
                    size: 80,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Document Preview',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
