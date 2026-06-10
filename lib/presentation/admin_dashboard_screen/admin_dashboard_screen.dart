import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import './widgets/teachers_tab.dart';
import './widgets/classes_tab.dart';
import './widgets/subjects_tab.dart';
import './widgets/assignments_tab.dart';
import './widgets/reports_tab.dart';
import './widgets/student_enrollment_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;

  final _tabs = const [
    _TabItem('Teachers', Icons.people_outlined),
    _TabItem('Classes', Icons.class_outlined),
    _TabItem('Subjects', Icons.book_outlined),
    _TabItem('Assignments', Icons.assignment_outlined),
    _TabItem('Enrollment', Icons.how_to_reg_outlined),
    _TabItem('Reports', Icons.bar_chart_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SupabaseService.getCurrentUserProfile();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
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
              'Sign Out',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SupabaseService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signUpLoginScreen,
        (_) => false,
      );
    }
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Testing Connection...',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 16),
            Text('Checking Supabase connection...'),
          ],
        ),
      ),
    );

    final result = await SupabaseService.testConnection();
    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Connection Test Results',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Initialized', result['isInitialized'] == true),
              _buildResultRow(
                'Authenticated',
                result['isAuthenticated'] == true,
              ),
              _buildResultRow(
                'Users Table',
                result['usersTableAccess'] == true,
              ),
              _buildResultRow(
                'Classes Table',
                result['classesTableAccess'] == true,
              ),
              const SizedBox(height: 8),
              Text(
                'User ID: ${result['currentUserId']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                'Role: ${result['currentUserRole']}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (result['error'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Error: ${result['error']}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? AppTheme.success : AppTheme.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: success ? AppTheme.success : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Text(
              'Do you want to sign out and exit the app?',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
        if (shouldExit ?? false) {
          await SupabaseService.signOut();
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        TeachersTab(),
                        ClassesTab(),
                        SubjectsTab(),
                        AssignmentsTab(),
                        StudentEnrollmentTab(),
                        ReportsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.8),
            radius: 1.0,
            colors: [AppTheme.primary.withAlpha(20), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.shadowLight.withAlpha(25),
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
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_currentUser != null)
                  Text(
                    _currentUser!.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _testConnection,
            icon: Icon(
              Icons.bug_report_rounded,
              color: AppTheme.textSecondary,
              size: 22,
            ),
            tooltip: 'Test DB Connection',
          ),
          IconButton(
            onPressed: _signOut,
            icon: Icon(
              Icons.logout_rounded,
              color: AppTheme.textSecondary,
              size: 22,
            ),
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.shadowLight.withAlpha(15),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.shadowLight.withAlpha(25),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textMuted,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: _tabs
            .map((t) => Tab(icon: Icon(t.icon, size: 16), text: t.label))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem(this.label, this.icon);
}
