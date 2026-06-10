import '../../../core/app_export.dart';

class AssignmentsTab extends StatefulWidget {
  const AssignmentsTab({super.key});

  @override
  State<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<AssignmentsTab> {
  List<AssignmentModel> _assignments = [];
  List<UserModel> _teachers = [];
  List<ClassModel> _classes = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getTeacherAssignments(''), // get all
        SupabaseService.listUsers(role: 'teacher'),
        SupabaseService.getClasses(),
        SupabaseService.getSubjects(),
      ]);
      if (mounted) {
        setState(() {
          _assignments = results[0] as List<AssignmentModel>;
          _teachers = results[1] as List<UserModel>;
          _classes = results[2] as List<ClassModel>;
          _subjects = results[3] as List<SubjectModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAssignDialog() async {
    String? selectedTeacherId;
    String? selectedClassId;
    String? selectedSubjectId;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Assign Teacher',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Teacher dropdown
                _buildDropdown(
                  label: 'Teacher',
                  value: selectedTeacherId,
                  items: _teachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedTeacherId = v),
                ),
                const SizedBox(height: 12),
                // Class dropdown
                _buildDropdown(
                  label: 'Class',
                  value: selectedClassId,
                  items: _classes
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedClassId = v),
                ),
                const SizedBox(height: 12),
                // Subject dropdown
                _buildDropdown(
                  label: 'Subject',
                  value: selectedSubjectId,
                  items: _subjects
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (selectedTeacherId == null ||
                    selectedClassId == null ||
                    selectedSubjectId == null) {
                  return;
                }
                final messenger = ScaffoldMessenger.of(context); // ignore: use_build_context_synchronously
                final result = await SupabaseService.assignTeacherToClass(
                  teacherId: selectedTeacherId!,
                  classId: selectedClassId!,
                  subjectId: selectedSubjectId!,
                );
                if (result != null && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(
                    ctx, // ignore: use_build_context_synchronously
                    true,
                  );
                } else if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to assign teacher. Check Supabase logs.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                      backgroundColor: AppTheme.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Assign',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true) _loadData();
  }

  Future<void> _showDeleteAssignmentDialog(
    AssignmentModel assignment,
  ) async {
    final teacherName = _teachers
        .where((t) => t.id == assignment.teacherId)
        .firstOrNull
        ?.name ?? 'Unknown';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Remove Assignment',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Remove $teacherName from ${assignment.className} - ${assignment.subjectName}?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      final success = await SupabaseService.removeTeacherAssignment(
        assignment.id,
      );
      if (success && mounted) {
        _loadData();
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to remove assignment. Check Supabase logs.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13),
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
                'Teacher Assignments',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _showAssignDialog,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Assign Teacher',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _assignments.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.assignment_outlined,
                    title: 'No Assignments Yet',
                    description:
                        'Assign teachers to classes and subjects to enable session creation.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final a = _assignments[index];
                    return Container(
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
                                  a.className ?? 'Unknown Class',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${a.subjectName ?? "Unknown Subject"} · ${a.teacherId}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            tooltip: 'Remove Assignment',
                            onPressed: () =>
                                _showDeleteAssignmentDialog(a),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
