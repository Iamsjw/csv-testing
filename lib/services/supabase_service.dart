import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/attendance_model.dart';

class SupabaseService {
  static const String _projectUrl = 'https://fgmdixxhzwhgaiajcxal.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZnbWRpeHhoendoZ2FpYWpjeGFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2NzM1NzQsImV4cCI6MjA5MzI0OTU3NH0.YDXk2lWWlN5SAN1MoXnL0JSVj8c7F_ZI_EOGclb3eas';

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentAuthUser => client.auth.currentUser;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _projectUrl,
      anonKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: true,
      ),
    );
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUp(
    String email,
    String password,
    String name,
    String role,
  ) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'role': role},
    );
    if (response.user != null) {
      await client.from('users').upsert({
        'id': response.user!.id,
        'name': name,
        'email': email,
        'role': role,
      });
    }
    return response;
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ─── User Profile ──────────────────────────────────────────────────────────
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  static Future<UserModel?> getCurrentUserProfile() async {
    final user = currentAuthUser;
    if (user == null) return null;
    return getUserProfile(user.id);
  }

  // ─── Classes & Subjects ───────────────────────────────────────────────────
  static Future<List<ClassModel>> getClasses() async {
    try {
      debugPrint('[Supabase] getClasses called');
      final data = await client.from('classes').select().order('name');
      debugPrint('[Supabase] getClasses returned ${data.length} classes');
      return (data as List)
          .map((e) => ClassModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[Supabase] getClasses failed: $e');
      debugPrint('[Supabase] Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<List<SubjectModel>> getSubjects() async {
    try {
      debugPrint('[Supabase] getSubjects called');
      final data = await client.from('subjects').select().order('name');
      debugPrint('[Supabase] getSubjects returned ${data.length} subjects');
      return (data as List)
          .map((e) => SubjectModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[Supabase] getSubjects failed: $e');
      debugPrint('[Supabase] Stack trace: $stackTrace');
      return [];
    }
  }

  // ─── Teacher Assignments ──────────────────────────────────────────────────
  static Future<List<AssignmentModel>> getTeacherAssignments(
    String teacherId,
  ) async {
    try {
      debugPrint(
        '[Supabase] getTeacherAssignments called for teacherId=$teacherId',
      );
      var query = client
          .from('teacher_assignments')
          .select('*, classes(name), subjects(name)');
      if (teacherId.isNotEmpty) {
        query = query.eq('teacher_id', teacherId);
      }
      final data = await query;
      debugPrint(
        '[Supabase] getTeacherAssignments returned ${data.length} assignments',
      );
      return (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        return AssignmentModel.fromMap({
          ...map,
          'class_name': (map['classes'] as Map?)?['name'],
          'subject_name': (map['subjects'] as Map?)?['name'],
        });
      }).toList();
    } catch (e, stackTrace) {
      debugPrint('[Supabase] getTeacherAssignments failed: $e');
      debugPrint('[Supabase] Stack trace: $stackTrace');
      return [];
    }
  }

  // ─── Sessions ─────────────────────────────────────────────────────────────
  static Future<SessionModel?> createSession({
    required String teacherId,
    required String classId,
    required String subjectId,
    required String code,
    required String securityLevel,
    required int rssiThreshold,
    required int durationSeconds,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final endTime = now.add(Duration(seconds: durationSeconds));
      final data = await client
          .from('sessions')
          .insert({
            'teacher_id': teacherId,
            'class_id': classId,
            'subject_id': subjectId,
            'code': code,
            'security_level': securityLevel,
            'rssi_threshold': rssiThreshold,
            'start_time': now.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'is_active': true,
          })
          .select()
          .single();
      return SessionModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> endSession(String sessionId) async {
    try {
      await client
          .from('sessions')
          .update({
            'is_active': false,
            'end_time': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateSessionSecurityLevel(
    String sessionId,
    String securityLevel,
  ) async {
    try {
      await client
          .from('sessions')
          .update({'security_level': securityLevel})
          .eq('id', sessionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<SessionModel?> getActiveSessionByCode(String code) async {
    try {
      final data = await client
          .from('sessions')
          .select()
          .eq('code', code)
          .eq('is_active', true)
          .maybeSingle();
      if (data == null) return null;
      return SessionModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  static Future<SessionModel?> getActiveSessionForTeacher(
    String teacherId,
  ) async {
    try {
      final data = await client
          .from('sessions')
          .select()
          .eq('teacher_id', teacherId)
          .eq('is_active', true)
          .maybeSingle();
      if (data == null) return null;
      return SessionModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  // ─── Attendance ───────────────────────────────────────────────────────────
  static Future<bool> markAttendance({
    required String studentId,
    required String sessionId,
  }) async {
    try {
      // Check for duplicate
      final existing = await client
          .from('attendance')
          .select()
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .eq('status', 'present')
          .maybeSingle();
      if (existing != null) return false; // already marked

      final attendanceRecord = await client
          .from('attendance')
          .insert({
            'student_id': studentId,
            'session_id': sessionId,
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'present',
          })
          .select()
          .single();

      // Log the action — best-effort only; do NOT fail the whole operation
      try {
        await client.from('attendance_logs').insert({
          'attendance_id': attendanceRecord['id'],
          'action': 'marked',
          'performed_by': studentId,
          'student_id': studentId,
          'session_id': sessionId,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (logErr) {
        debugPrint('[Supabase] attendance_logs insert failed (non-critical): $logErr');
      }

      return true;
    } catch (e) {
      // If insert failed due to duplicate key, treat as "already marked" not an error
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('duplicate') || errStr.contains('unique')) {
        debugPrint('[Supabase] Duplicate attendance caught: $e');
        return false;
      }
      debugPrint('[Supabase] markAttendance failed: $e');
      return false;
    }
  }

  static Future<bool> revokeAttendance({
    required String attendanceId,
    required String teacherId,
    required String studentId,
    required String sessionId,
    String? reason,
  }) async {
    try {
      await client
          .from('attendance')
          .update({'status': 'revoked'})
          .eq('id', attendanceId);

      await client.from('attendance_logs').insert({
        'action': 'revoked',
        'performed_by': teacherId,
        'student_id': studentId,
        'session_id': sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'reason': reason ?? '',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<AttendanceModel>> getSessionAttendance(
    String sessionId,
  ) async {
    try {
      final data = await client
          .from('attendance')
          .select('*, users(name, email)')
          .eq('session_id', sessionId)
          .order('timestamp');
      return (data as List).map((e) {
        final map = e as Map<String, dynamic>;
        return AttendanceModel.fromMap({
          ...map,
          'student_name': (map['users'] as Map?)?['name'],
          'student_email': (map['users'] as Map?)?['email'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<AttendanceModel>> getStudentAttendanceHistory(
    String studentId,
  ) async {
    try {
      final data = await client
          .from('attendance')
          .select('*, sessions(*, subjects(name))')
          .eq('student_id', studentId)
          .order('timestamp', ascending: false);
      return (data as List)
          .map((e) => AttendanceModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> hasStudentMarkedAttendance({
    required String studentId,
    required String sessionId,
  }) async {
    try {
      final data = await client
          .from('attendance')
          .select()
          .eq('student_id', studentId)
          .eq('session_id', sessionId)
          .eq('status', 'present')
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  // ─── Teacher Reports ──────────────────────────────

  /// Get all sessions for a teacher with attendance stats.
  /// Returns a list of maps with session data + present_count, total_count.
  static Future<List<Map<String, dynamic>>> getTeacherSessionsWithStats(
    String teacherId,
  ) async {
    try {
      debugPrint('[Reports] Loading sessions for teacher: $teacherId');
      // Fetch all sessions for this teacher with class/subject names
      final sessions = await client
          .from('sessions')
          .select('*, classes(name), subjects(name)')
          .eq('teacher_id', teacherId)
          .order('start_time', ascending: false);
      if (sessions.isEmpty) return [];

      // Fetch attendance stats for all these sessions
      final sessionIds = (sessions as List).map((s) => s['id']).toList();
      final attendance = await client
          .from('attendance')
          .select('session_id, status')
          .filter('session_id', 'in', sessionIds);

      // Aggregate attendance by session
      final stats = <String, Map<String, int>>{};
      for (final a in attendance) {
        final sid = a['session_id'] as String;
        stats.putIfAbsent(sid, () => {'present': 0, 'total': 0});
        stats[sid]!['total'] = stats[sid]!['total']! + 1;
        if (a['status'] == 'present') {
          stats[sid]!['present'] = stats[sid]!['present']! + 1;
        }
      }

      // Merge stats into session data
      final result = (sessions as List).map((session) {
        final sid = session['id'] as String;
        final s = stats[sid] ?? {'present': 0, 'total': 0};
        return {
          ...session as Map<String, dynamic>,
          'present_count': s['present'],
          'total_count': s['total'],
        };
      }).toList();

      debugPrint('[Reports] Loaded ${result.length} sessions with stats');
      return result;
    } catch (e, stackTrace) {
      debugPrint('[Reports] Failed to get teacher sessions: $e');
      debugPrint('[Reports] Stack: $stackTrace');
      return [];
    }
  }

  /// Get attendance records for a specific teacher session.
  static Future<List<Map<String, dynamic>>> getSessionAttendanceForReport(
    String sessionId,
  ) async {
    try {
      final data = await client
          .from('attendance')
          .select('*, users(name, email)')
          .eq('session_id', sessionId)
          .order('timestamp');
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Reports] Failed to get session attendance: $e');
      return [];
    }
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────
  static RealtimeChannel subscribeToSessionAttendance(
    String sessionId,
    void Function(List<Map<String, dynamic>>) onUpdate,
  ) {
    debugPrint('[Realtime] Subscribing to attendance for session: $sessionId');
    return client
        .channel('attendance_$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'attendance',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            debugPrint(
              '[Realtime] Attendance change detected: ${payload.toString()}',
            );
            // Fetch latest attendance and push to UI
            getSessionAttendance(sessionId)
                .then((records) {
                  debugPrint(
                    '[Realtime] Fetched ${records.length} records, pushing to UI',
                  );
                  onUpdate(records.map((e) => e.toMap()).toList());
                })
                .catchError((e) {
                  debugPrint('[Realtime] Error fetching attendance: $e');
                });
          },
        )
        .subscribe();
  }

  // ─── Connection Test ──────────────────────────────────────
  static Future<Map<String, dynamic>> testConnection() async {
    final result = {
      'isInitialized': false,
      'isAuthenticated': false,
      'currentUserId': '',
      'currentUserRole': '',
      'usersTableAccess': false,
      'classesTableAccess': false,
      'error': '',
    };

    try {
      // Check if Supabase is initialized
      final client = Supabase.instance.client;
      result['isInitialized'] = true;

      // Check authentication
      final user = currentAuthUser;
      if (user == null) {
        result['error'] = 'Not authenticated';
        return result;
      }
      result['isAuthenticated'] = true;
      result['currentUserId'] = user.id;

      // Check current user's role
      final profile = await getUserProfile(user.id);
      if (profile == null) {
        result['error'] = 'User profile not found in users table';
        return result;
      }
      result['currentUserRole'] = profile.role;

      // Test users table access
      try {
        await client.from('users').select('id').limit(1);
        result['usersTableAccess'] = true;
      } catch (e) {
        result['error'] = 'Users table access failed: $e';
      }

      // Test classes table access
      try {
        await client.from('classes').select('id').limit(1);
        result['classesTableAccess'] = true;
      } catch (e) {
        result['error'] = '${result['error']}\nClasses table access failed: $e';
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('[Supabase] testConnection failed: $e');
      debugPrint('[Supabase] Stack trace: $stackTrace');
      result['error'] = e.toString();
      return result;
    }
  }

  // ─── Admin: User Management ─────────────────────────────

  /// Admin creates a new user (teacher or student).
  /// Uses signUp which works with anon key (no admin privileges needed).
  /// NOTE: Disable email confirmation in Supabase dashboard > Auth > Settings for this to work seamlessly.
  /// Returns the created UserModel or null on failure.
  static Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );
      if (response.user != null) {
        // Ensure profile exists in users table
        await client.from('users').upsert({
          'id': response.user!.id,
          'name': name,
          'email': email,
          'role': role,
        });
        return getUserProfile(response.user!.id);
      }
      return null;
    } catch (e) {
      debugPrint('[Admin] Failed to create user: $e');
      return null;
    }
  }

  /// List all users by role. Note: class_id join removed because the
  /// actual users table lacks a foreign key to classes. To re-enable
  /// class name lookups, add class_id column and FK to classes table.
  static Future<List<UserModel>> listUsers({String? role}) async {
    try {
      debugPrint('[Admin] listUsers called with role=$role');
      debugPrint('[Admin] Current user: ${currentAuthUser?.id}');
      var query = client.from('users').select();
      if (role != null) {
        query = query.eq('role', role);
      }
      final data = await query.order('name');
      debugPrint('[Admin] listUsers returned ${data.length} users');
      return (data as List)
          .map((e) => UserModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('[Admin] Failed to list users: $e');
      debugPrint('[Admin] Stack trace: $stackTrace');
      return [];
    }
  }

  // ─── Admin: Class Management ─────────────────────────────

  static Future<ClassModel?> createClass(String name) async {
    try {
      final data = await client
          .from('classes')
          .insert({'name': name})
          .select()
          .single();
      return ClassModel.fromMap(data);
    } catch (e) {
      debugPrint('[Admin] Failed to create class: $e');
      return null;
    }
  }

  static Future<bool> updateClass(String id, String name) async {
    try {
      await client.from('classes').update({'name': name}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to update class: $e');
      return false;
    }
  }

  static Future<bool> deleteClass(String id) async {
    try {
      await client.from('classes').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to delete class: $e');
      return false;
    }
  }

  // ─── Admin: Subject Management ─────────────────────────────

  static Future<SubjectModel?> createSubject(String name) async {
    try {
      final data = await client
          .from('subjects')
          .insert({'name': name})
          .select()
          .single();
      return SubjectModel.fromMap(data);
    } catch (e) {
      debugPrint('[Admin] Failed to create subject: $e');
      return null;
    }
  }

  static Future<bool> updateSubject(String id, String name) async {
    try {
      await client.from('subjects').update({'name': name}).eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to update subject: $e');
      return false;
    }
  }

  static Future<bool> deleteSubject(String id) async {
    try {
      await client.from('subjects').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to delete subject: $e');
      return false;
    }
  }

  // ─── Admin: Teacher Assignments ──────────────────────────

  static Future<AssignmentModel?> assignTeacherToClass({
    required String teacherId,
    required String classId,
    required String subjectId,
  }) async {
    try {
      final data = await client
          .from('teacher_assignments')
          .insert({
            'teacher_id': teacherId,
            'class_id': classId,
            'subject_id': subjectId,
          })
          .select()
          .single();
      return AssignmentModel.fromMap(data);
    } catch (e) {
      debugPrint('[Admin] Failed to assign teacher: $e');
      return null;
    }
  }

  static Future<bool> removeTeacherAssignment(String assignmentId) async {
    try {
      await client.from('teacher_assignments').delete().eq('id', assignmentId);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to remove assignment: $e');
      return false;
    }
  }

  /// Update user profile (name, email, role, class_id).
  static Future<bool> updateUser(
    String userId, {
    required Map<String, dynamic> data,
  }) async {
    try {
      await client.from('users').update(data).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to update user: $e');
      return false;
    }
  }

  /// Delete user from users table.
  /// Note: This does NOT delete from auth.users (requires service role key).
  static Future<bool> deleteUser(String userId) async {
    try {
      await client.from('users').delete().eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to delete user: $e');
      return false;
    }
  }

  // ─── Admin: Student Enrollment ───────────────────────────

  static Future<bool> enrollStudentInClass({
    required String studentId,
    required String classId,
  }) async {
    try {
      await client
          .from('users')
          .update({'class_id': classId})
          .eq('id', studentId);
      return true;
    } catch (e) {
      debugPrint('[Admin] Failed to enroll student: $e');
      return false;
    }
  }

  // ─── Admin: Reports ───────────────────────────────────────

  /// Get attendance records for a class with session and subject info.
  /// Consolidated sessions reference to avoid duplicate table alias errors.
  static Future<List<Map<String, dynamic>>> getClassAttendanceReport(
    String classId,
  ) async {
    try {
      final data = await client
          .from('attendance')
          .select('''
            *,
            sessions!inner(class_id, subject_id, subjects(name)),
            users!inner(name, email)
          ''')
          .eq('sessions.class_id', classId);
      return (data as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[Admin] Failed to get class report: $e');
      return [];
    }
  }

  static Future<List<AttendanceModel>> getStudentAttendanceReport(
    String studentId,
  ) async {
    return getStudentAttendanceHistory(studentId);
  }
}
