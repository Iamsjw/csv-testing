import 'package:flutter/material.dart';

import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/student_attendance_screen/student_attendance_screen.dart';
import '../presentation/teacher_session_screen/teacher_session_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String signUpLoginScreen = '/sign-up-login-screen';
  static const String teacherSessionScreen = '/teacher-session-screen';
  static const String studentAttendanceScreen = '/student-attendance-screen';
  static const String adminDashboardScreen = '/admin-dashboard-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SignUpLoginScreen(),
    signUpLoginScreen: (context) => const SignUpLoginScreen(),
    teacherSessionScreen: (context) => const TeacherSessionScreen(),
    studentAttendanceScreen: (context) => const StudentAttendanceScreen(),
    adminDashboardScreen: (context) => const AdminDashboardScreen(),
  };
}
