import 'dart:async';

import '../../../core/app_export.dart';
import '../../../services/csv_export_service.dart';

class TeacherReportsTab extends StatefulWidget {
  final VoidCallback? onBack;

  const TeacherReportsTab({super.key, this.onBack});

  @override
  State<TeacherReportsTab> createState() => _TeacherReportsTabState();
}

class _TeacherReportsTabState extends State<TeacherReportsTab> {
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic>? _selectedSession;
  List<Map<String, dynamic>> _sessionAttendance = [];
  bool _isLoading = true;
  bool _isLoadingDetail = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _selectedSession = null;
      _sessionAttendance = [];
    });
    try {
      final user = await SupabaseService.getCurrentUserProfile();
      if (user == null) return;
      final data = await SupabaseService.getTeacherSessionsWithStats(user.id);
      if (mounted) {
        setState(() {
          _sessions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[TeacherReports] Failed to load sessions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSessionDetail(Map<String, dynamic> session) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedSession = session;
    });
    try {
      final records = await SupabaseService.getSessionAttendanceForReport(
        session['id'] as String,
      );
      if (mounted) {
        setState(() {
          _sessionAttendance = records;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      debugPrint('[TeacherReports] Failed to load detail: $e');
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _downloadSessionCsv(Map<String, dynamic> session) async {
    try {
      final records = await SupabaseService.getSessionAttendanceForReport(
        session['id'] as String,
      );
      if (mounted) {
        await CsvExportService.downloadCsvFromMap(
          context: context,
          sessionData: session,
          attendanceData: records,
        );
      }
    } catch (e) {
      debugPrint('[TeacherReports] Failed to download CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download CSV: $e',
              style: GoogleFonts.plusJakartaSans(fontSize: 12),
            ),
            backgroundColor: AppTheme.errorSoft,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredSessions {
    var list = _sessions;
    if (_startDate != null) {
      list = list.where((s) {
        final ts = DateTime.parse(s['start_time'] as String);
        return !ts.isBefore(_startDate!);
      }).toList();
    }
    if (_endDate != null) {
      final end = _endDate!.add(const Duration(days: 1));
      list = list.where((s) {
        final ts = DateTime.parse(s['start_time'] as String);
        return !ts.isAfter(end);
      }).toList();
    }
    return list;
  }

  String _formatDate(String? iso) {
    if (iso == null) return '--';
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '--';
    final d = DateTime.parse(iso);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        if (_selectedSession == null) ...[
          _buildDateFilter(),
          const SizedBox(height: 12),
          Expanded(child: _buildSessionsList()),
        ] else ...[
          _buildDetailView(),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    final totalSessions = _sessions.length;
    var totalPresent = 0;
    var totalAttendance = 0;
    for (final s in _sessions) {
      totalPresent += (s['present_count'] as int? ?? 0);
      totalAttendance += (s['total_count'] as int? ?? 0);
    }
    final rate = totalAttendance == 0
        ? 0.0
        : totalPresent / totalAttendance * 100;

    return Container(
      padding: const EdgeInsets.all(16),
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
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
            ),
          Text(
            'My Sessions',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          if (_selectedSession == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$totalSessions Sessions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (_selectedSession == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rate >= 75
                    ? AppTheme.successSoft
                    : rate >= 50
                    ? AppTheme.warningSoft
                    : AppTheme.errorSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${rate.toStringAsFixed(0)}% Present',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: rate >= 75
                      ? AppTheme.success
                      : rate >= 50
                      ? AppTheme.warning
                      : AppTheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _startDate != null
                        ? AppTheme.primary.withAlpha(77)
                        : AppTheme.shadowLight.withAlpha(25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: _startDate != null
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${_formatDate(_startDate!.toIso8601String())} - ${_formatDate(_endDate!.toIso8601String())}'
                            : 'Date Range (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: _startDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_startDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: _loadSessions,
            child: Text(
              'Refresh',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Widget _buildSessionsList() {
    final filtered = _filteredSessions;
    if (filtered.isEmpty) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.history_rounded,
          title: 'No Sessions Found',
          description: _startDate != null
              ? 'Try adjusting the date range filter.'
              : 'Start your first session to see reports here.',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final session = filtered[index];
        final present = session['present_count'] as int? ?? 0;
        final total = session['total_count'] as int? ?? 0;
        final rate = total == 0 ? 0.0 : present / total * 100;
        final isActive = session['is_active'] as bool? ?? false;
        final className = (session['classes'] as Map?)?['name'] ?? 'Unknown';
        final subjectName = (session['subjects'] as Map?)?['name'] ?? 'Unknown';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? AppTheme.success.withAlpha(77)
                  : AppTheme.shadowLight.withAlpha(25),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _loadSessionDetail(session),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTheme.successSoft
                                : AppTheme.primary.withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isActive
                                ? Icons.sensors_rounded
                                : Icons.check_circle_rounded,
                            color: isActive
                                ? AppTheme.success
                                : AppTheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$subjectName - $className',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_formatDate(session['start_time'])} at ${_formatTime(session['start_time'])}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'LIVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Present',
                          value: '$present',
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Total',
                          value: '$total',
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          label: 'Rate',
                          value: '${rate.toStringAsFixed(0)}%',
                          color: rate >= 75
                              ? AppTheme.success
                              : rate >= 50
                              ? AppTheme.warning
                              : AppTheme.error,
                        ),
                        const Spacer(),
                        // Download button for this session
                        IconButton(
                          onPressed: () =>
                              _downloadSessionCsv(session),
                          icon: Icon(
                            Icons.download_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          tooltip: 'Download CSV',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailView() {
    if (_selectedSession == null) return const SizedBox.shrink();

    final session = _selectedSession!;
    final className = (session['classes'] as Map?)?['name'] ?? 'Unknown';
    final subjectName = (session['subjects'] as Map?)?['name'] ?? 'Unknown';
    final present = session['present_count'] as int? ?? 0;
    final total = session['total_count'] as int? ?? 0;

    return Expanded(
      child: Column(
        children: [
          // Back button + session info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSession = null;
                      _sessionAttendance = [];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$subjectName - $className',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatDate(session['start_time'])} | Code: ${session['code']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Download button for this session
                IconButton(
                  onPressed: () => _downloadSessionCsv(session),
                  icon: Icon(
                    Icons.download_rounded,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  tooltip: 'Download CSV',
                ),
              ],
            ),
          ),
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(
                  label: 'Present',
                  value: '$present',
                  color: AppTheme.success,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Total',
                  value: '$total',
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  label: 'Revoked',
                  value: '${total - present}',
                  color: AppTheme.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Attendance list
          Expanded(
            child: _isLoadingDetail
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _sessionAttendance.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      icon: Icons.people_outline_rounded,
                      title: 'No Attendance Yet',
                      description:
                          'Students haven\'t marked attendance for this session.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sessionAttendance.length,
                    itemBuilder: (context, index) {
                      final record = _sessionAttendance[index];
                      final name = record['users']?['name'] ?? 'Unknown';
                      final email = record['users']?['email'] ?? '--';
                      final isPresent = record['status'] == 'present';
                      final ts = DateTime.parse(record['timestamp'] as String);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
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
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isPresent
                                    ? AppTheme.successSoft
                                    : AppTheme.errorSoft,
                              ),
                              child: Icon(
                                isPresent
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                color: isPresent
                                    ? AppTheme.success
                                    : AppTheme.error,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    email,
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
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? AppTheme.successSoft
                                        : AppTheme.errorSoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPresent ? 'Present' : 'Revoked',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isPresent
                                          ? AppTheme.success
                                          : AppTheme.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
