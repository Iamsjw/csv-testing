import '../../../core/app_export.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/csv_export_service.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<ClassModel> _classes = [];
  List<UserModel> _students = [];
  String? _selectedClassId;
  String? _selectedStudentId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classes = await SupabaseService.getClasses();
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedClassId == null) {
      setState(() => _students = []);
      return;
    }
    try {
      final allStudents = await SupabaseService.listUsers(role: 'student');
      if (mounted) {
        setState(() {
          _students = allStudents
              .where((s) => s.classId == _selectedClassId)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('[Reports] Failed to load students: $e');
    }
  }

  Future<void> _loadReport() async {
    if (_selectedClassId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getClassAttendanceReport(
        _selectedClassId!,
      );
      // Filter by student if selected
      var filtered = data as List;
      if (_selectedStudentId != null) {
        filtered = filtered
            .where((r) => r['student_id'] == _selectedStudentId)
            .toList();
      }
      // Filter by date range if set
      if (_startDate != null || _endDate != null) {
        filtered = filtered.where((r) {
          final ts = DateTime.parse(r['timestamp'] as String);
          if (_startDate != null && ts.isBefore(_startDate!)) return false;
          if (_endDate != null) {
            final end = _endDate!.add(const Duration(days: 1));
            if (ts.isAfter(end)) return false;
          }
          return true;
        }).toList();
      }
      if (mounted) {
        setState(() {
          _reportData = {'records': filtered, 'total': filtered.length};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadReportCsv() {
    final records = _reportData?['records'] as List? ?? [];
    if (records.isEmpty) return;

    final className = _classes
        .where((c) => c.id == _selectedClassId)
        .firstOrNull
        ?.name ?? 'Unknown';

    CsvExportService.downloadAdminReportCsv(
      context: context,
      className: className,
      records: records,
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

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _classes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Column(
      children: [
        // Header
        Container(
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
              Text(
                'Attendance Reports',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        // Filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Row 1: Class + Student
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'Select Class',
                      value: _selectedClassId,
                      items: _classes
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedClassId = v;
                          _selectedStudentId = null;
                          _reportData = null;
                          _students = [];
                        });
                        if (v != null) _loadStudents();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDropdown(
                      label: 'Select Student (Optional)',
                      value: _selectedStudentId,
                      items: _students
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedStudentId = v;
                          _reportData = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 2: Date range + Generate button
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
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
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _startDate != null && _endDate != null
                                    ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
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
                    ),
                    onPressed: _selectedClassId != null ? _loadReport : null,
                    child: Text(
                      'Generate',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Report
        if (_reportData != null) Expanded(child: _buildReportView()),
      ],
    );
  }

  Widget _buildReportView() {
    final records = _reportData?['records'] as List? ?? [];
    final total = records.length;

    if (total == 0) {
      return Center(
        child: EmptyStateWidget(
          icon: Icons.bar_chart_outlined,
          title: 'No Records Found',
          description: 'Try adjusting filters or selecting a different class.',
        ),
      );
    }

    // Group by subject
    final bySubject = <String, Map<String, dynamic>>{};
    for (final r in records) {
      final subjectName = r['sessions']?['subjects']?['name'] ?? 'Unknown';
      if (!bySubject.containsKey(subjectName)) {
        bySubject[subjectName] = {'present': 0, 'total': 0};
      }
      bySubject[subjectName]!['total']++;
      if (r['status'] == 'present') {
        bySubject[subjectName]!['present']++;
      }
    }

    // Calculate overall stats
    final presentCount = records.where((r) => r['status'] == 'present').length;
    final overallRate = total == 0 ? 0.0 : presentCount / total * 100;

    return Column(
      children: [
        // Stats row
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Total: $total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Download CSV button
              GestureDetector(
                onTap: _downloadReportCsv,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'CSV',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: overallRate >= 75
                      ? AppTheme.successSoft
                      : overallRate >= 50
                      ? AppTheme.warningSoft
                      : AppTheme.errorSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${overallRate.toStringAsFixed(0)}% Present',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overallRate >= 75
                        ? AppTheme.success
                        : overallRate >= 50
                        ? AppTheme.warning
                        : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pie Chart
        if (total > 0)
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: presentCount.toDouble(),
                            title: 'Present',
                            color: AppTheme.success,
                            radius: 60,
                            titleStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: (total - presentCount).toDouble(),
                            title: 'Other',
                            color: AppTheme.error,
                            radius: 60,
                            titleStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        centerSpaceRadius: 30,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(
                          color: AppTheme.success,
                          label: 'Present',
                          value: '$presentCount',
                        ),
                        const SizedBox(height: 8),
                        _LegendItem(
                          color: AppTheme.error,
                          label: 'Revoked/Other',
                          value: '${total - presentCount}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Bar Chart - Attendance by Subject
        if (bySubject.isNotEmpty)
          SizedBox(
            height: 220,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      bySubject.values
                          .map((e) => (e['total'] as int).toDouble())
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barGroups: bySubject.entries.toList().asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final data = entry.value.value;
                    final total = data['total'] as int;
                    final present = data['present'] as int;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: total.toDouble(),
                          color: AppTheme.primary.withAlpha(77),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: present.toDouble(),
                          color: AppTheme.success,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) {
                          final keys = bySubject.keys.toList();
                          if (value.toInt() >= keys.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Transform.rotate(
                              angle: -0.4,
                              child: Text(
                                keys[value.toInt()],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.shadowLight.withAlpha(25),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        // Subject list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Breakdown by Subject',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: bySubject.entries.map((entry) {
              final subject = entry.key;
              final data = entry.value;
              final rate = data['total'] == 0
                  ? 0.0
                  : data['present'] / data['total'] * 100;
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Present: ${data['present']} / ${data['total']}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: rate >= 75
                            ? AppTheme.successSoft
                            : rate >= 50
                            ? AppTheme.warningSoft
                            : AppTheme.errorSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${rate.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.shadowLight.withAlpha(25),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textDisabled,
                ),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
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
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
