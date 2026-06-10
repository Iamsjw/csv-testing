import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/attendance_model.dart';
import '../../../widgets/empty_state_widget.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../theme/app_theme.dart';

class AttendanceHistoryWidget extends StatelessWidget {
  final List<AttendanceModel> history;

  const AttendanceHistoryWidget({super.key, required this.history});

  // Group by date, then by subject
  Map<String, Map<String, List<AttendanceModel>>> get _grouped {
    final dateMap = <String, Map<String, List<AttendanceModel>>>{};
    for (final record in history) {
      final date = _formatDate(record.timestamp);
      dateMap.putIfAbsent(date, () => {});
      final subject = record.subjectName ?? 'Unknown Subject';
      dateMap[date]!.putIfAbsent(subject, () => []).add(record);
    }
    return dateMap;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.day == yesterday.day &&
        dt.month == yesterday.month &&
        dt.year == yesterday.year) {
      return 'Yesterday';
    }
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

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
                            Icons.history_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Attendance History',
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
                          color: AppTheme.primaryCyan.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${history.where((h) => h.isPresent).length} present',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryCyan,
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
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: EmptyStateWidget(
                      icon: Icons.event_available_outlined,
                      title: 'No Attendance Yet',
                      description:
                          'Your attendance records will appear here once you mark attendance in a session.',
                    ),
                  )
                else ...[
                  // Summary stats
                  _buildSummaryRow(),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.shadowLight.withAlpha(13),
                  ),
                  // Records grouped by date, then by subject
                  ..._grouped.entries.map(
                    (dateEntry) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                          child: Text(
                            dateEntry.key,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        // Subjects under this date
                        ...dateEntry.value.entries.map((subjectEntry) {
                          final subjectName = subjectEntry.key;
                          final records = subjectEntry.value;
                          final presentCount = records
                              .where((r) => r.isPresent)
                              .length;
                          final totalCount = records.length;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject header with summary
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  28,
                                  6,
                                  20,
                                  6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.book_outlined,
                                      size: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        subjectName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$presentCount/$totalCount present',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: presentCount == totalCount
                                            ? AppTheme.success
                                            : AppTheme.warning,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Records for this subject
                              ...records.map(
                                (record) => _HistoryRow(
                                  record: record,
                                  formatTime: _formatTime,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    final present = history.where((h) => h.isPresent).length;
    final revoked = history.where((h) => h.isRevoked).length;
    final total = history.length;
    final rate = total == 0 ? 0.0 : present / total;

    Color rateColor() {
      if (rate >= 0.75) return AppTheme.success;
      if (rate >= 0.5) return AppTheme.warning;
      return AppTheme.error;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryTile(
              value: present.toString(),
              label: 'Present',
              color: AppTheme.success,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppTheme.shadowLight.withAlpha(20),
          ),
          Expanded(
            child: _SummaryTile(
              value: revoked.toString(),
              label: 'Revoked',
              color: AppTheme.error,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppTheme.shadowLight.withAlpha(20),
          ),
          Expanded(
            child: _SummaryTile(
              value: '${(rate * 100).toStringAsFixed(0)}%',
              label: 'Rate',
              color: rateColor(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SummaryTile({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final AttendanceModel record;
  final String Function(DateTime) formatTime;

  const _HistoryRow({required this.record, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: record.isPresent
                  ? AppTheme.successSoft
                  : AppTheme.errorSoft,
            ),
            child: Icon(
              record.isPresent ? Icons.check_rounded : Icons.close_rounded,
              color: record.isPresent ? AppTheme.success : AppTheme.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session ${record.sessionId.substring(0, 8).toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  formatTime(record.timestamp),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadgeWidget.attendanceStatus(
            record.isPresent
                ? AttendanceStatus.present
                : AttendanceStatus.revoked,
          ),
        ],
      ),
    );
  }
}
