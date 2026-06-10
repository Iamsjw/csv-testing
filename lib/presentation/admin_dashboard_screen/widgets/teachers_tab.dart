import '../../../core/app_export.dart';

class TeachersTab extends StatefulWidget {
  const TeachersTab({super.key});

  @override
  State<TeachersTab> createState() => _TeachersTabState();
}

class _TeachersTabState extends State<TeachersTab> {
  List<UserModel> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[UI] TeachersTab._loadTeachers() called');
      final teachers = await SupabaseService.listUsers(role: 'teacher');
      debugPrint(
        '[UI] TeachersTab._loadTeachers() got ${teachers.length} teachers',
      );
      if (mounted) {
        setState(() {
          _teachers = teachers;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[UI] TeachersTab._loadTeachers() failed: $e');
      debugPrint('[UI] Stack trace: $stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddTeacherDialog() async {
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
          'Add Teacher',
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
                  role: 'teacher',
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
                        'Failed to create teacher. Check Supabase logs.',
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

    if (result == true) _loadTeachers();

    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  Future<void> _showEditTeacherDialog(UserModel teacher) async {
    final nameController = TextEditingController(text: teacher.name);
    final emailController = TextEditingController(text: teacher.email);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Teacher',
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
                  teacher.id,
                  data: {
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                  },
                );
                if (success && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx, true);
                } else if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update teacher. Check Supabase logs.',
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
    );

    if (result == true) _loadTeachers();
    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _showDeleteDialog(UserModel teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Teacher',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${teacher.name}? This action cannot be undone.',
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
      final success = await SupabaseService.deleteUser(teacher.id);
      if (success && mounted) {
        _loadTeachers();
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete teacher. Check Supabase logs.',
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
                'Teachers',
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
                onPressed: _showAddTeacherDialog,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Teacher',
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
          child: _teachers.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.people_outline_rounded,
                    title: 'No Teachers Yet',
                    description:
                        'Add teachers to assign them to classes and subjects.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final teacher = _teachers[index];
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
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryBlue.withAlpha(38),
                            ),
                            child: Center(
                              child: Text(
                                teacher.name.isNotEmpty
                                    ? teacher.name[0].toUpperCase()
                                    : 'T',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
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
                                  teacher.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  teacher.email,
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
                              Icons.edit_outlined,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            tooltip: 'Edit Teacher',
                            onPressed: () =>
                                _showEditTeacherDialog(teacher),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            tooltip: 'Delete Teacher',
                            onPressed: () => _showDeleteDialog(teacher),
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
