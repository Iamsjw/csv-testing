import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class RoleSelectorWidget extends StatelessWidget {
  final String selectedRole;
  final void Function(String) onRoleChanged;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = [
      ('admin', Icons.admin_panel_settings_outlined, 'Admin', AppTheme.error),
      ('teacher', Icons.school_outlined, 'Teacher', AppTheme.primaryBlue),
      (
        'student',
        Icons.person_outline_rounded,
        'Student',
        AppTheme.primaryCyan,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Role',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: roles.map((role) {
            final isSelected = selectedRole == role.$1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: role.$1 != 'student' ? 8 : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? role.$4.withAlpha(38)
                        : AppTheme.surface.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? role.$4.withAlpha(128)
                          : AppTheme.shadowLight.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onRoleChanged(role.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            role.$2,
                            size: 22,
                            color: isSelected ? role.$4 : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            role.$3,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? role.$4 : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
