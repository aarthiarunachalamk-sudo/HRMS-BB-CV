import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/roledashboard.dart';
import 'theme_config.dart';
import 'constellation_background.dart';
import 'boom_in_widget.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateOfBirthController =
      TextEditingController();
  final TextEditingController _dateOfJoiningController =
      TextEditingController();
  
  String _selectedDepartment = 'Development';
  bool _agreedToTerms = false;

  final List<String> _departments = [
    'Development',
    'Design',
    'Human Resources',
    'Finance',
    'Marketing',
    'Management'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _dateOfJoiningController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _pickDate({
    required TextEditingController controller,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? initialDate,
  }) async {
    final fallbackDate = initialDate ?? DateTime.now();
    final safeInitialDate = fallbackDate.isBefore(firstDate)
        ? firstDate
        : fallbackDate.isAfter(lastDate)
            ? lastDate
            : fallbackDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: ThemeConfig.purpleAccent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      controller.text = _formatDate(selectedDate);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to the Terms & Conditions and Privacy Policy'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      
      // Success modal
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: ThemeConfig.getCardBg(dialogContext),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: ThemeConfig.getCardBorder(dialogContext),
              width: 1.5,
            ),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF00FF87),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Success!',
                style: TextStyle(
                  color: ThemeConfig.getTextPrimary(dialogContext),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Account for ${_nameController.text} has been successfully submitted for registration approval!',
            style: TextStyle(
              color: ThemeConfig.getTextSecondary(dialogContext),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // pop modal
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const RoleDashboard(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 550),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Color(0xFF00C6FF), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _toggleBrightnessMode() {
    final currentMode = MyApp.themeNotifier.value;
    if (currentMode == ThemeMode.dark) {
      MyApp.themeNotifier.value = ThemeMode.light;
    } else {
      MyApp.themeNotifier.value = ThemeMode.dark;
    }
    setState(() {}); // refresh screen
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
        accentColor: ThemeConfig.purpleAccent,
        child: SafeArea(
          child: Stack(
            children: [
              // Back Button
              Positioned(
                top: 8,
                left: 12,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Theme Mode toggle top right
              Positioned(
                top: 8,
                right: 12,
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    color: ThemeConfig.purpleAccent,
                  ),
                  onPressed: _toggleBrightnessMode,
                  tooltip: 'Toggle Light/Dark Theme',
                ),
              ),

              // Form Scrollable Container
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        // Avatar picker layout
                        _buildAvatarSection(isDark),
                        const SizedBox(height: 20),

                        // Headlines
                        Text(
                          'Create Your Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Let's get you started with BitByte HRMS",
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Container Card wrapped in BoomIn pop animation
                        BoomInWidget(
                          duration: const Duration(milliseconds: 900),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: cardBorder, width: 1.5),
                              boxShadow: ThemeConfig.getPremiumShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Full Name Field
                                _buildLabel('Full Name', textSecondary),
                                _buildTextField(
                                  controller: _nameController,
                                  placeholder: 'Aarthi M',
                                  icon: Icons.person_outline_rounded,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your full name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Employee Code Field
                                _buildLabel('Employee Code', textSecondary),
                                _buildTextField(
                                  controller: _codeController,
                                  placeholder: 'EMP1001',
                                  icon: Icons.badge_outlined,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter employee code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Email Address Field
                                _buildLabel('Email Address', textSecondary),
                                _buildTextField(
                                  controller: _emailController,
                                  placeholder: 'aarthi.m@bitbyte.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter email';
                                    }
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(val)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Mobile Number Field
                                _buildLabel('Mobile Number', textSecondary),
                                _buildTextField(
                                  controller: _phoneController,
                                  placeholder: '+91 98765 43210',
                                  icon: Icons.phone_iphone_rounded,
                                  keyboardType: TextInputType.phone,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter mobile number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Date of Birth Field
                                _buildLabel('Date of Birth', textSecondary),
                                _buildDateField(
                                  controller: _dateOfBirthController,
                                  placeholder: 'DD/MM/YYYY',
                                  icon: Icons.cake_outlined,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  onTap: () {
                                    final today = DateTime.now();
                                    _pickDate(
                                      controller: _dateOfBirthController,
                                      firstDate: DateTime(today.year - 70),
                                      lastDate: DateTime(
                                        today.year - 18,
                                        today.month,
                                        today.day,
                                      ),
                                      initialDate: DateTime(
                                        today.year - 25,
                                        today.month,
                                        today.day,
                                      ),
                                    );
                                  },
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please select date of birth';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Date of Joining Field
                                _buildLabel('Date of Joining', textSecondary),
                                _buildDateField(
                                  controller: _dateOfJoiningController,
                                  placeholder: 'DD/MM/YYYY',
                                  icon: Icons.event_available_outlined,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  onTap: () {
                                    final today = DateTime.now();
                                    _pickDate(
                                      controller: _dateOfJoiningController,
                                      firstDate: DateTime(today.year - 10),
                                      lastDate: DateTime(
                                        today.year + 1,
                                        today.month,
                                        today.day,
                                      ),
                                      initialDate: today,
                                    );
                                  },
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please select date of joining';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Department Selector Field
                                _buildLabel('Department', textSecondary),
                                _buildDropdownField(isDark, textPrimary, cardBg, cardBorder),
                                const SizedBox(height: 24),

                                // Terms & Conditions Checkbox
                                _buildCheckboxRow(cardBorder, textSecondary),
                                const SizedBox(height: 24),

                                // Sign Up Action Button
                                _buildSignUpButton(),
                                const SizedBox(height: 20),

                                // Login Navigation link
                                _buildLoginLink(textSecondary),
                              ],
                            ),
                          ),
                        ),
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

  // Widget to build Avatar Circle with floating edit badge
  Widget _buildAvatarSection(bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF0072FF).withAlpha(128),
                width: 1.5,
              ),
            ),
          ),
          CircleAvatar(
            radius: 38,
            backgroundColor: isDark ? const Color(0xFF0C1625) : const Color(0xFFF1F5F9),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 40,
              color: Color(0xFF00C6FF),
            ),
          ),
          // Purple "+" button badge at bottom right
          Positioned(
            bottom: 0,
            right: 0,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: ThemeConfig.purpleAccent,
              child: const Icon(
                Icons.add,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String labelText, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2.0),
      child: Text(
        labelText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Shared Form Text Field Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        hintText: placeholder,
        hintStyle: TextStyle(color: textSecondary.withAlpha(102), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4FACFE), size: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? cardBorder : const Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
    required VoidCallback onTap,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(color: textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        hintText: placeholder,
        hintStyle: TextStyle(color: textSecondary.withAlpha(102), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4FACFE), size: 18),
        suffixIcon: Icon(
          Icons.calendar_month_outlined,
          color: textSecondary.withAlpha(180),
          size: 18,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? cardBorder : const Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // Department Dropdown Widget
  Widget _buildDropdownField(bool isDark, Color textPrimary, Color cardBg, Color cardBorder) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? cardBorder : const Color(0xFFCBD5E1), width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedDepartment,
          dropdownColor: cardBg,
          style: TextStyle(color: textPrimary, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8E9CAE)),
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.business_outlined, color: Color(0xFF4FACFE), size: 18),
            contentPadding: EdgeInsets.zero,
          ),
          items: _departments.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedDepartment = newValue!;
            });
          },
        ),
      ),
    );
  }

  // Checkbox widget
  Widget _buildCheckboxRow(Color cardBorder, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: const Color(0xFF00FF87),
            checkColor: Colors.black,
            side: BorderSide(color: cardBorder, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (bool? value) {
              setState(() {
                _agreedToTerms = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the ',
              style: TextStyle(color: textSecondary, fontSize: 12),
              children: const [
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: Color(0xFF00C6FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF00C6FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Gradient Signup Action Button
  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _submitForm,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              ThemeConfig.purpleAccent,
              Color(0xFF00FF87),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.purpleAccent.withAlpha(51),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Sign Up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // Login bottom link
  Widget _buildLoginLink(Color textSecondary) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                final tween =
                    Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeInOutCubic));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        },
        child: Text.rich(
          TextSpan(
            text: 'Already have an account? ',
            style: TextStyle(color: textSecondary, fontSize: 13),
            children: const [
              TextSpan(
                text: 'Login',
                style: TextStyle(
                  color: Color(0xFF00C6FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
