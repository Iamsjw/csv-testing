import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class _DemoAccount {
  final String role;
  final String email;
  final String password;
  final Color color;
  final IconData icon;

  const _DemoAccount({
    required this.role,
    required this.email,
    required this.password,
    required this.color,
    required this.icon,
  });
}

class DemoCredentialsWidget extends StatelessWidget {
  final void Function(String email, String password) onAutofill;

  const DemoCredentialsWidget({super.key, required this.onAutofill});

  static const List<_DemoAccount> _accounts = [
    _DemoAccount(
      role: 'Admin',
      email: 'admin@upasthitix.edu',
      password: 'Admin@2025',
      color: Color(0xFFFF6B6B),
      icon: Icons.admin_panel_settings_outlined,
    ),
    _DemoAccount(
      role: 'Teacher',
      email: 'priya.sharma@upasthitix.edu',
      password: 'Teacher@2025',
      color: AppTheme.primaryBlue,
      icon: Icons.school_outlined,
    ),
    _DemoAccount(
      role: 'Teacher',
      email: 'rahul.verma@upasthitix.edu',
      password: 'Teacher@2025',
      color: AppTheme.primaryBlue,
      icon: Icons.school_outlined,
    ),
    _DemoAccount(
      role: 'Student',
      email: 'arjun.mehta@upasthitix.edu',
      password: 'Student@2025',
      color: AppTheme.primaryCyan,
      icon: Icons.person_outline_rounded,
    ),
    _DemoAccount(
      role: 'Student',
      email: 'sneha.patel@upasthitix.edu',
      password: 'Student@2025',
      color: AppTheme.primaryCyan,
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassMorphism(
        borderRadius: BorderRadius.circular(20),
        opacity: 0.05,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(13),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.shadowLight.withAlpha(25),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.key_rounded,
                        color: AppTheme.warning,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Demo Accounts — Tap to autofill',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warning,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: AppTheme.shadowLight.withAlpha(20),
                  thickness: 1,
                ),
                ..._accounts.map(
                  (acc) => _AccountRow(
                    account: acc,
                    onTap: () => onAutofill(acc.email, acc.password),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final _DemoAccount account;
  final VoidCallback onTap;

  const _AccountRow({required this.account, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: account.color.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(account.icon, size: 16, color: account.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: account.color.withAlpha(38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          account.role.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: account.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Copy email button
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: account.email));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Email copied',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                    backgroundColor: AppTheme.surfaceVariant,
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withAlpha(13),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.copy_rounded,
                  size: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Use button
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: account.color.withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: account.color.withAlpha(77),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Use',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: account.color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
