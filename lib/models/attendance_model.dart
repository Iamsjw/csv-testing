class AttendanceModel {
  final String id;
  final String studentId;
  final String sessionId;
  final DateTime timestamp;
  final String status;
  final String? studentName;
  final String? studentEmail;
  final String? subjectName;

  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.timestamp,
    required this.status,
    this.studentName,
    this.studentEmail,
    this.subjectName,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    // Extract subject name from nested sessions->subjects join
    String? extractedSubjectName;
    final sessionData = map['sessions'];
    if (sessionData is Map<String, dynamic>) {
      final subjectData = sessionData['subjects'];
      if (subjectData is Map<String, dynamic>) {
        extractedSubjectName = subjectData['name'] as String?;
      }
    }
    return AttendanceModel(
      id: map['id'] as String? ?? '',
      studentId: map['student_id'] as String? ?? '',
      sessionId: map['session_id'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
      status: map['status'] as String? ?? 'present',
      studentName: map['student_name'] as String?,
      studentEmail: map['student_email'] as String?,
      subjectName: extractedSubjectName ?? map['subject_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'student_id': studentId,
    'session_id': sessionId,
    'timestamp': timestamp.toIso8601String(),
    'status': status,
  };

  bool get isPresent => status == 'present';
  bool get isRevoked => status == 'revoked';
}

class ClassModel {
  final String id;
  final String name;

  const ClassModel({required this.id, required this.name});

  factory ClassModel.fromMap(Map<String, dynamic> map) => ClassModel(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

class SubjectModel {
  final String id;
  final String name;

  const SubjectModel({required this.id, required this.name});

  factory SubjectModel.fromMap(Map<String, dynamic> map) => SubjectModel(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
}

class AssignmentModel {
  final String id;
  final String teacherId;
  final String classId;
  final String subjectId;
  final String? className;
  final String? subjectName;

  const AssignmentModel({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    this.className,
    this.subjectName,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map) => AssignmentModel(
    id: map['id'] as String? ?? '',
    teacherId: map['teacher_id'] as String? ?? '',
    classId: map['class_id'] as String? ?? '',
    subjectId: map['subject_id'] as String? ?? '',
    className: map['class_name'] as String?,
    subjectName: map['subject_name'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'teacher_id': teacherId,
    'class_id': classId,
    'subject_id': subjectId,
  };
}

class AttendanceHistoryModel {
  final String subjectId;
  final String subjectName;
  final int totalSessions;
  final int attended;

  const AttendanceHistoryModel({
    required this.subjectId,
    required this.subjectName,
    required this.totalSessions,
    required this.attended,
  });

  double get percentage =>
      totalSessions == 0 ? 0 : (attended / totalSessions) * 100;

  factory AttendanceHistoryModel.fromMap(Map<String, dynamic> map) =>
      AttendanceHistoryModel(
        subjectId: map['subject_id'] as String? ?? '',
        subjectName: map['subject_name'] as String? ?? '',
        totalSessions: (map['total_sessions'] as num?)?.toInt() ?? 0,
        attended: (map['attended'] as num?)?.toInt() ?? 0,
      );
}
