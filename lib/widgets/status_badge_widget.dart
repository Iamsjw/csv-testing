import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AttendanceStatus { present, revoked, pending, absent }

enum SessionStatus { active, expired, notStarted }

class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.fontSize = 11,
    this.padding,
  });

  factory StatusBadgeWidget.attendanceStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return StatusBadgeWidget(
          label: 'PRESENT',
          color: AppTheme.successSoft,
          textColor: AppTheme.success,
        );
      case AttendanceStatus.revoked:
        return StatusBadgeWidget(
          label: 'REVOKED',
          color: AppTheme.errorSoft,
          textColor: AppTheme.error,
        );
      case AttendanceStatus.absent:
        return StatusBadgeWidget(
          label: 'ABSENT',
          color: AppTheme.warningSoft,
          textColor: AppTheme.warning,
        );
      case AttendanceStatus.pending:
        return StatusBadgeWidget(
          label: 'PENDING',
          color: AppTheme.primaryBlue.withAlpha(30),
          textColor: AppTheme.primaryBlue,
        );
    }
  }

  factory StatusBadgeWidget.sessionStatus(SessionStatus status) {
    switch (status) {
      case SessionStatus.active:
        return StatusBadgeWidget(
          label: '● LIVE',
          color: AppTheme.successSoft,
          textColor: AppTheme.success,
        );
      case SessionStatus.expired:
        return StatusBadgeWidget(
          label: 'EXPIRED',
          color: AppTheme.errorSoft,
          textColor: AppTheme.error,
        );
      case SessionStatus.notStarted:
        return StatusBadgeWidget(
          label: 'INACTIVE',
          color: AppTheme.shadowLight.withAlpha(30),
          textColor: AppTheme.textMuted,
        );
    }
  }

  factory StatusBadgeWidget.role(String role) {
    Color bg, fg;
    switch (role.toLowerCase()) {
      case 'admin':
        bg = AppTheme.errorSoft;
        fg = AppTheme.error;
        break;
      case 'teacher':
        bg = AppTheme.primaryBlue.withAlpha(30);
        fg = AppTheme.primaryBlue;
        break;
      default:
        bg = AppTheme.primaryCyan.withAlpha(30);
        fg = AppTheme.primaryCyan;
    }
    return StatusBadgeWidget(
      label: role.toUpperCase(),
      color: bg,
      textColor: fg,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppTheme.textPrimary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
