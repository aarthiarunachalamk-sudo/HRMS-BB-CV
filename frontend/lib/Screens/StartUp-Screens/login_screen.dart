import 'package:flutter/material.dart';
import 'package:hrms_mobileapp_bitbyte/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/superadmin_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/CEO_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/MD_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/HR_dadhborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Finance_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Admin_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/ITTeam_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Manager-dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/MarketingTeam_dashborad.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/TL_dashborad.dart';
import 'boom_in_widget.dart';
import 'register_screen.dart';
import 'constellation_background.dart';
import 'logo_widget.dart';
import 'theme_config.dart';
import 'Change_Password.dart';
import 'package:hrms_mobileapp_bitbyte/Screens/Dashboard/Employee_dashborad.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _employeeCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _employeeCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleBrightnessMode() {
    final currentMode = MyApp.themeNotifier.value;
    MyApp.themeNotifier.value =
        currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() {});
  }

  Future<void> _submitLogin() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final response = await http.post(
      Uri.parse('http://192.168.1.54:8000/api/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _employeeCodeController.text.trim(),
        'password': _passwordController.text,
      }),
    );

    final data = jsonDecode(response.body);

    if (data['success'] == true) {
  // OTC first login check
  if (data['requires_password_change'] == true) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ChangePasswordScreen(
        employeeId: data['user_id'] ?? '',
        otc: _passwordController.text,
      )),
      (route) => false,
    );
    return;
  }
  final role = data['role'];
  Widget dashboard;
  if (role == 'superadmin') {
    dashboard = SuperAdminDashboard(email: data['email']);
  } else if (role == 'ceo') {
    dashboard = CeoDashboard(
      email: data['email'],
      firstName: data['first_name'] ?? '',
      userId: data['user_id'] ?? '',
    );
  } else if (role == 'md') {
    dashboard = MdDashboard(
      email: data['email'],
      firstName: data['first_name'] ?? '',
      userId: data['user_id'] ?? '',
    );
  } else if (role == 'hr') {
  dashboard = HrDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'finance') {
  dashboard = FinanceDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'admin') {
  dashboard = AdminDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'it') {
  dashboard = ITTeamDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'manager') {
  dashboard = ManagerDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'marketing') {
  dashboard = MarketingTeamDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'tl') {
  dashboard = TLDashboard(email: data['email'], firstName: data['first_name'] ?? '', userId: data['user_id'] ?? '');
} else if (role == 'employee') {
  dashboard = EmployeeDashboard(
    email: data['email'],
    firstName: data['first_name'] ?? '',
    userId: data['user_id'] ?? '',
  );
} else {
  dashboard = SuperAdminDashboard(email: data['email']);
}

 Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => dashboard,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 550),
    ),
    (route) => false,
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(data['message'] ?? 'Login failed')),
  );
}
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server error! Backend running ah check pannunga')),
    );
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
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 12,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: textPrimary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                top: 8,
                right: 12,
                child: IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: ThemeConfig.blueAccent,
                  ),
                  onPressed: _toggleBrightnessMode,
                  tooltip: 'Toggle Light/Dark Theme',
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BitByteLogo(size: 86, showSubtitle: false),
                        const SizedBox(height: 24),
                        Text(
                          'Welcome To Bit Byte Technologies',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue to BitByte HRMS',
                          style: TextStyle(color: textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 30),
                        BoomInWidget(
                          duration: const Duration(milliseconds: 850),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: cardBorder, width: 1.5),
                              boxShadow: ThemeConfig.getPremiumShadow(context),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Employee Code', textSecondary),
                                _buildTextField(
                                  controller: _employeeCodeController,
                                  placeholder: 'EMP1001',
                                  icon: Icons.badge_outlined,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Please enter employee code';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                _buildLabel('Password', textSecondary),
                                _buildPasswordField(
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  cardBorder: cardBorder,
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        activeColor: ThemeConfig.blueAccent,
                                        checkColor: Colors.black,
                                        side: BorderSide(
                                          color: cardBorder,
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Remember me',
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: ThemeConfig.blueAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _submitLogin,
                                  child: Container(
                                    width: double.infinity,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: ThemeConfig.blueGradient,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: ThemeConfig.blueAccent
                                              .withAlpha(70),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            ),
                            child: RichText(
                              text: TextSpan(
                                text: "New employee? ",
                                style: TextStyle(color: textSecondary, fontSize: 13),
                                children: const [
                                  TextSpan(
                                    text: 'Register Here',
                                    style: TextStyle(
                                      color: Color(0xFF00C6FF),
                                      fontWeight: FontWeight.bold,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String labelText, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor:
            isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        hintText: placeholder,
        hintStyle: TextStyle(color: textSecondary.withAlpha(102), fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4FACFE), size: 18),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? cardBorder : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardBorder,
  }) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: textPrimary, fontSize: 14),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor:
            isDark ? const Color(0xFF0A121E) : const Color(0xFFF1F5F9),
        hintText: 'Enter password',
        hintStyle: TextStyle(color: textSecondary.withAlpha(102), fontSize: 14),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF4FACFE),
          size: 18,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: textSecondary,
            size: 18,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? cardBorder : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}