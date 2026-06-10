import '../../../core/app_export.dart';
import '../../../services/csv_export_service.dart';

class SessionReportScreen extends StatelessWidget {
  final SessionModel session;
  final List<AttendanceModel> attendance;
  final String className;
  final String subjectName;

  const SessionReportScreen({
    super.key,
    required this.session,
    required this.attendance,
    required this.className,
    required this.subjectName,
  });

  int get _presentCount => attendance.where((a) => a.isPresent).length;
  int get _revokedCount => attendance.where((a) => a.isRevoked).length;
  int get _totalStudents => attendance.length;

  double get _attendanceRate =>
      _totalStudents == 0 ? 0 : (_presentCount / _totalStudents) * 100;

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  Future<void> _downloadCsv(BuildContext context) async {
    await CsvExportService.downloadCsv(
      context: context,
      subjectName: subjectName,
      className: className,
      session: session,
      attendance: attendance,
    );
  }

  Color _getRateColor(double rate) {
    if (rate >= 75) return AppTheme.success;
    if (rate >= 50) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final rateColor = _getRateColor(_attendanceRate);
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.8),
                  radius: 1.0,
                  colors: [AppTheme.primary.withAlpha(20), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.shadowLight.withAlpha(15),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.shadowLight.withAlpha(25),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.primaryGradient,
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Report',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '$subjectName - $className',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Session complete banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.success.withAlpha(26),
                              AppTheme.success.withAlpha(13),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.success.withAlpha(77),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withAlpha(38),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.success,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Session Complete',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatDate(session.startTime)} | ${_formatTime(session.startTime)} - ${session.endTime != null ? _formatTime(session.endTime!) : "N/A"}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              label: 'Present',
                              value: _presentCount.toString(),
                              color: AppTheme.success,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Revoked',
                              value: _revokedCount.toString(),
                              color: AppTheme.error,
                              icon: Icons.cancel_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryCard(
                              label: 'Total',
                              value: _totalStudents.toString(),
                              color: AppTheme.primary,
                              icon: Icons.people_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Attendance rate
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: rateColor.withAlpha(13),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: rateColor.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.percent_rounded,
                              color: rateColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Attendance Rate: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '${_attendanceRate.toStringAsFixed(1)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: rateColor,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Duration: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Attendance records header
                      Row(
                        children: [
                          Text(
                            'Attendance Records',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$_totalStudents',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Download CSV button
                          GestureDetector(
                            onTap: () => _downloadCsv(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(77),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.download_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'CSV',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Attendance list
                      if (attendance.isEmpty)
                        EmptyStateWidget(
                          icon: Icons.people_outline_rounded,
                          title: 'No Attendance Records',
                          description:
                              'No students marked attendance in this session.',
                        )
                      else
                        ...attendance.asMap().entries.map((entry) {
                          final index = entry.key;
                          final record = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.shadowLight.withAlpha(25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: record.isPresent
                                        ? AppTheme.successSoft
                                        : AppTheme.errorSoft,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: record.isPresent
                                            ? AppTheme.success
                                            : AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        record.studentName ?? 'Unknown',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        record.studentEmail ?? 'No email',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: record.isPresent
                                            ? AppTheme.successSoft
                                            : AppTheme.errorSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        record.isPresent
                                            ? 'Present'
                                            : 'Revoked',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: record.isPresent
                                              ? AppTheme.success
                                              : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(record.timestamp),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(51), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
