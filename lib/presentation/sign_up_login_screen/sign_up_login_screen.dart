import 'dart:async';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:ui';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import './widgets/demo_credentials_widget.dart';

class SignUpLoginScreen extends StatefulWidget {
  const SignUpLoginScreen({super.key});

  @override
  State<SignUpLoginScreen> createState() => _SignUpLoginScreenState();
}

class _SignUpLoginScreenState extends State<SignUpLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _entranceController;
  late AnimationController _logoController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;
  late Animation<double> _logoScale;
  late Animation<double> _logoPulse;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _entranceFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoPulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _entranceController.forward();
    _checkExistingSession(); // called once only
  }

  Future<void> _checkExistingSession() async {
    try {
      // Try to refresh the session first — this re-validates an expired access
      // token using the persisted refresh token, keeping users logged in.
      final currentSession = SupabaseService.client.auth.currentSession;
      if (currentSession != null) {
        try {
          await SupabaseService.client.auth.refreshSession();
        } catch (_) {
          // Refresh failed (e.g. refresh token expired) — fall through to
          // check currentAuthUser which will be null, showing the login screen.
        }
      }
    } catch (_) {}

    final user = SupabaseService.currentAuthUser;
    if (user == null) return;

    final profile = await SupabaseService.getUserProfile(user.id);
    if (profile == null || !mounted) return;

    switch (profile.role) {
      case 'teacher':
        Navigator.pushReplacementNamed(context, AppRoutes.teacherSessionScreen);
        break;
      case 'student':
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentAttendanceScreen,
        );
        break;
      case 'admin':
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboardScreen);
        break;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _logoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint(
        '[Auth] Attempting sign in for ${_emailController.text.trim()}',
      );
      final response = await SupabaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      debugPrint('[Auth] Sign in response: user=${response.user?.id}');
      if (response.user != null) {
        final profile = await SupabaseService.getUserProfile(response.user!.id);
        if (profile != null && mounted) {
          _navigateByRole(profile.role);
        } else if (mounted) {
          setState(() => _errorMessage = 'Profile not found. Contact admin.');
        }
      }
    } on AuthException catch (e) {
      debugPrint('[Auth] AuthException: ${e.message}');
      if (mounted) {
        setState(() {
          if (e.message.toLowerCase().contains('invalid')) {
            _errorMessage = 'Invalid credentials — use the demo accounts below';
          } else {
            _errorMessage = e.message;
          }
        });
      }
    } catch (e) {
      debugPrint('[Auth] Unexpected error: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(String role) {
    if (role == 'teacher') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.teacherSessionScreen,
        (_) => false,
      );
    } else if (role == 'student') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.studentAttendanceScreen,
        (_) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.adminDashboardScreen,
        (_) => false,
      );
    }
  }

  void _autofillCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 0 : 24,
                    vertical: 24,
                  ),
                  child: AnimatedBuilder(
                    animation: _entranceController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _entranceFade,
                        child: SlideTransition(
                          position: _entranceSlide,
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: isTablet ? 440 : double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLogoSection(),
                          const SizedBox(height: 36),
                          _buildAuthCard(),
                          const SizedBox(height: 16),
                          _buildDemoButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.7, -0.6),
          radius: 1.4,
          colors: [AppTheme.primary.withAlpha(20), AppTheme.background],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return ScaleTransition(
          scale: _logoScale,
          child: Transform.scale(scale: _logoPulse.value, child: child),
        );
      },
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withAlpha(64),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'UpasthitiX',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Smart Attendance System',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha(22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.shadowLight.withAlpha(20), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(),
                  ],
                  const SizedBox(height: 28),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return _buildField(
      label: 'Email Address',
      hint: 'you@example.com',
      controller: _emailController,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        final email = v?.trim() ?? '';
        if (email.isEmpty) return 'Email required';
        if (!email.contains('@') || !email.contains('.')) {
          return 'Enter a valid email (e.g. user@example.com)';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _buildField(
      label: 'Password',
      hint: '••••••••',
      controller: _passwordController,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppTheme.textMuted,
          size: 20,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password required';
        if (v.length < 6) return 'Min 6 characters';
        return null;
      },
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppTheme.textDisabled,
            ),
            prefixIcon: Icon(prefixIcon, color: AppTheme.textMuted, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppTheme.surfaceVariant.withAlpha(64),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primary.withAlpha(128),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.error.withAlpha(128),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.error.withAlpha(179),
                width: 1.5,
              ),
            ),
            errorStyle: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.error,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withAlpha(77), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close_rounded, size: 16, color: AppTheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha(77),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleSignIn,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withAlpha(26),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoButton() {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Accounts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DemoCredentialsWidget(onAutofill: _autofillCredentials),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.shadowLight.withAlpha(25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.key_rounded, color: AppTheme.warning, size: 16),
            const SizedBox(width: 8),
            Text(
              'Demo Accounts',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              color: AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
