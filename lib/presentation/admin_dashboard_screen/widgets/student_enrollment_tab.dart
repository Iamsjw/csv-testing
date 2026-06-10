import '../../../core/app_export.dart';

class StudentEnrollmentTab extends StatefulWidget {
  const StudentEnrollmentTab({super.key});

  @override
  State<StudentEnrollmentTab> createState() => _StudentEnrollmentTabState();
}

class _StudentEnrollmentTabState extends State<StudentEnrollmentTab> {
  List<UserModel> _students = [];
  List<ClassModel> _classes = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'enrolled', 'unenrolled'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.listUsers(role: 'student'),
        SupabaseService.getClasses(),
      ]);
      if (mounted) {
        setState(() {
          _students = results[0] as List<UserModel>;
          _classes = results[1] as List<ClassModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filteredStudents {
    switch (_filter) {
      case 'enrolled':
        return _students.where((s) => s.classId != null).toList();
      case 'unenrolled':
        return _students.where((s) => s.classId == null).toList();
      default:
        return _students;
    }
  }

  Future<void> _showAddStudentDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Student',
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
              TextFormField(
                controller: nameController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email required';
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Valid email required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                  ),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
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
              if (formKey.currentState!.validate()) {
                // ignore: use_build_context_synchronously
                final messenger = ScaffoldMessenger.of(context);
                final user = await SupabaseService.createUser(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  name: nameController.text.trim(),
                  role: 'student',
                );
                if (user != null && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(
                    ctx, // ignore: use_build_context_synchronously
                    true,
                  );
                } else if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to create student. Check Supabase logs.',
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
            },
            child: Text(
              'Add',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) _loadData();

    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  Future<void> _showEditStudentDialog(UserModel student) async {
    final nameController = TextEditingController(text: student.name);
    final emailController = TextEditingController(text: student.email);
    String? selectedClassId = student.classId;
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
            'Edit Student',
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
                TextFormField(
                  controller: nameController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                    ),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email required';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Valid email required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Class dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class (Optional)',
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
                          value: selectedClassId,
                          hint: Text(
                            'Select class...',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textDisabled,
                            ),
                          ),
                          isExpanded: true,
                          dropdownColor: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
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
                if (formKey.currentState!.validate()) {
                  // ignore: use_build_context_synchronously
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await SupabaseService.updateUser(
                    student.id,
                    data: {
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'class_id': selectedClassId,
                    },
                  );
                  if (success && mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx, true);
                  } else if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update student. Check Supabase logs.',
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
              },
              child: Text(
                'Save',
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
    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _showDeleteStudentDialog(UserModel student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Student',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${student.name}? This action cannot be undone.',
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
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
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
              'Delete',
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
      final success = await SupabaseService.deleteUser(student.id);
      if (success && mounted) {
        _loadData();
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete student. Check Supabase logs.',
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

  Future<void> _showEnrollDialog(UserModel student) async {
    String? classId = student.classId;
    final formKey = GlobalKey<FormState>();

    await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState2) => AlertDialog(
            backgroundColor: AppTheme.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              student.classId != null ? 'Change Class' : 'Enroll Student',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    student.email,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Class',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        value: classId,
                        isExpanded: true,
                        hint: Text(
                          'Choose a class...',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        items: _classes.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState2(() => classId = value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: classId == null
                    ? null
                    : () async {
                        // ignore: use_build_context_synchronously
                        final messenger = ScaffoldMessenger.of(context);
                        final success =
                            await SupabaseService.enrollStudentInClass(
                          studentId: student.id,
                          classId: classId!,
                        );
                        if (success && mounted) {
                          // ignore: use_build_context_synchronously
                          Navigator.pop(
                            ctx, // ignore: use_build_context_synchronously
                            true,
                          );
                        } else if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to enroll student. Check Supabase logs.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                ),
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
                  student.classId != null ? 'Update' : 'Enroll',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((result) {
      if (result == true) _loadData();
    });
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
                'Students',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_students.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
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
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Student',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Filter chips
              _FilterChip(
                label: 'All',
                isSelected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Enrolled',
                isSelected: _filter == 'enrolled',
                onTap: () => setState(() => _filter = 'enrolled'),
              ),
              const SizedBox(width: 6),
              _FilterChip(
                label: 'Unenrolled',
                isSelected: _filter == 'unenrolled',
                onTap: () => setState(() => _filter = 'unenrolled'),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _filteredStudents.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.people_outline_rounded,
                    title: _filter == 'unenrolled'
                        ? 'All Students Enrolled'
                        : 'No Students Yet',
                    description: _filter == 'unenrolled'
                        ? 'All students are assigned to a class.'
                        : 'Add students to the system first.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredStudents.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = _filteredStudents[index];
                    final isEnrolled = student.classId != null;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEnrolled
                              ? AppTheme.success.withAlpha(40)
                              : AppTheme.warning.withAlpha(40),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isEnrolled
                                  ? AppTheme.successSoft
                                  : AppTheme.warningSoft,
                            ),
                            child: Center(
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0].toUpperCase()
                                    : 'S',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isEnrolled
                                      ? AppTheme.success
                                      : AppTheme.warning,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  student.email,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                if (isEnrolled)
                                  Text(
                                    'Class: ${student.className ?? 'Unknown'}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                else
                                  Text(
                                    'Not enrolled',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.warning,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            tooltip: 'Edit Student',
                            onPressed: () =>
                                _showEditStudentDialog(student),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            tooltip: 'Delete Student',
                            onPressed: () =>
                                _showDeleteStudentDialog(student),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: () => _showEnrollDialog(student),
                            style: TextButton.styleFrom(
                              foregroundColor: isEnrolled
                                  ? AppTheme.primary
                                  : AppTheme.success,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Text(
                              isEnrolled ? 'Change' : 'Enroll',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.shadowLight.withAlpha(25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
