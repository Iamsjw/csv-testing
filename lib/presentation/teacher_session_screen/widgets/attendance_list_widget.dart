import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/attendance_model.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../theme/app_theme.dart';

class AttendanceListWidget extends StatelessWidget {
  final List<AttendanceModel> attendance;
  final void Function(AttendanceModel) onRevokeAttendance;
  final bool isSessionActive;

  const AttendanceListWidget({
    super.key,
    required this.attendance,
    required this.onRevokeAttendance,
    required this.isSessionActive,
  });

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
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Attendance',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${attendance.where((a) => a.isPresent).length} present',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.shadowLight.withAlpha(13),
                ),
                if (attendance.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateWidget(
                      icon: Icons.how_to_reg_outlined,
                      title: 'No Attendance Yet',
                      description:
                          'Students will appear here as they mark attendance using the session code.',
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: attendance.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.shadowLight.withAlpha(10),
                      indent: 20,
                      endIndent: 20,
                    ),
                    itemBuilder: (context, index) {
                      final record = attendance[index];
                      return _AttendanceRow(
                        record: record,
                        index: index,
                        onRevoke: () => onRevokeAttendance(record),
                        isSessionActive: isSessionActive,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceRow extends StatefulWidget {
  final AttendanceModel record;
  final int index;
  final VoidCallback onRevoke;
  final bool isSessionActive;

  const _AttendanceRow({
    required this.record,
    required this.index,
    required this.onRevoke,
    required this.isSessionActive,
  });

  @override
  State<_AttendanceRow> createState() => _AttendanceRowState();
}

class _AttendanceRowState extends State<_AttendanceRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  bool get _canUndo {
    if (widget.record.isRevoked) return false;
    return widget.isSessionActive ||
        DateTime.now().difference(widget.record.timestamp).inMinutes < 5;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.record.isPresent
                      ? AppTheme.successSoft
                      : AppTheme.errorSoft,
                  border: Border.all(
                    color: widget.record.isPresent
                        ? AppTheme.success.withAlpha(77)
                        : AppTheme.error.withAlpha(77),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(widget.record.studentName),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.record.isPresent
                          ? AppTheme.success
                          : AppTheme.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Student info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.studentName ?? 'Unknown Student',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(widget.record.timestamp),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              StatusBadgeWidget.attendanceStatus(
                widget.record.isPresent
                    ? AttendanceStatus.present
                    : AttendanceStatus.revoked,
              ),
              // Undo button
              if (_canUndo) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onRevoke,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.error.withAlpha(77),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.undo_rounded,
                      size: 14,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
