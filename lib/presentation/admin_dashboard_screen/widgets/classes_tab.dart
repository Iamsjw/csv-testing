import '../../../core/app_export.dart';

class ClassesTab extends StatefulWidget {
  const ClassesTab({super.key});

  @override
  State<ClassesTab> createState() => _ClassesTabState();
}

class _ClassesTabState extends State<ClassesTab> {
  List<ClassModel> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[UI] ClassesTab._loadClasses() called');
      final classes = await SupabaseService.getClasses();
      debugPrint('[UI] ClassesTab._loadClasses() got ${classes.length} classes');
      if (mounted) {
        setState(() {
          _classes = classes;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[UI] ClassesTab._loadClasses() failed: $e');
      debugPrint('[UI] Stack trace: $stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddClassDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Class',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Class Name',
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
                final result = await SupabaseService.createClass(
                  controller.text.trim(),
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
                        'Failed to create class. Check Supabase logs.',
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

    if (result == true) _loadClasses();
    controller.dispose();
  }

  Future<void> _showEditClassDialog(ClassModel classModel) async {
    final controller = TextEditingController(text: classModel.name);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Class',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Class Name',
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
                final success = await SupabaseService.updateClass(
                  classModel.id,
                  controller.text.trim(),
                );
                if (success && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx, true);
                } else if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update class. Check Supabase logs.',
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

    if (result == true) _loadClasses();
    controller.dispose();
  }

  Future<void> _showDeleteClassDialog(ClassModel classModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Class',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${classModel.name}"? This action cannot be undone.',
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
      final success = await SupabaseService.deleteClass(classModel.id);
      if (success && mounted) {
        _loadClasses();
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete class. Check Supabase logs.',
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
                'Classes',
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
                onPressed: _showAddClassDialog,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Class',
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
          child: _classes.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.class_outlined,
                    title: 'No Classes Yet',
                    description:
                        'Add classes to assign teachers and enroll students.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final classModel = _classes[index];
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
                              color: AppTheme.primary.withAlpha(38),
                            ),
                            child: Icon(
                              Icons.class_,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              classModel.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            tooltip: 'Edit Class',
                            onPressed: () =>
                                _showEditClassDialog(classModel),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            tooltip: 'Delete Class',
                            onPressed: () =>
                                _showDeleteClassDialog(classModel),
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
