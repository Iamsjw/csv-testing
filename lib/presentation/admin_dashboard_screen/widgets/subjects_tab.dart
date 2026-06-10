import '../../../core/app_export.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('[UI] SubjectsTab._loadSubjects() called');
      final subjects = await SupabaseService.getSubjects();
      debugPrint(
        '[UI] SubjectsTab._loadSubjects() got ${subjects.length} subjects',
      );
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('[UI] SubjectsTab._loadSubjects() failed: $e');
      debugPrint('[UI] Stack trace: $stackTrace');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddSubjectDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Subject',
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
              labelText: 'Subject Name',
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
                final result = await SupabaseService.createSubject(
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
                        'Failed to create subject. Check Supabase logs.',
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

    if (result == true) _loadSubjects();
    controller.dispose();
  }

  Future<void> _showEditSubjectDialog(SubjectModel subject) async {
    final controller = TextEditingController(text: subject.name);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Subject',
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
              labelText: 'Subject Name',
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
                final success = await SupabaseService.updateSubject(
                  subject.id,
                  controller.text.trim(),
                );
                if (success && mounted) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx, true);
                } else if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to update subject. Check Supabase logs.',
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

    if (result == true) _loadSubjects();
    controller.dispose();
  }

  Future<void> _showDeleteSubjectDialog(SubjectModel subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Subject',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${subject.name}"? This action cannot be undone.',
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
      final success = await SupabaseService.deleteSubject(subject.id);
      if (success && mounted) {
        _loadSubjects();
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete subject. Check Supabase logs.',
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
                'Subjects',
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
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Subject',
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
          child: _subjects.isEmpty
              ? Center(
                  child: EmptyStateWidget(
                    icon: Icons.book_outlined,
                    title: 'No Subjects Yet',
                    description:
                        'Add subjects to assign them to teachers and classes.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
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
                            child: Icon(
                              Icons.book,
                              color: AppTheme.primaryBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subject.name,
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
                            tooltip: 'Edit Subject',
                            onPressed: () =>
                                _showEditSubjectDialog(subject),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outlined,
                              color: AppTheme.error,
                              size: 18,
                            ),
                            tooltip: 'Delete Subject',
                            onPressed: () =>
                                _showDeleteSubjectDialog(subject),
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
