class SessionModel {
  final String id;
  final String teacherId;
  final String classId;
  final String subjectId;
  final String code;
  final String securityLevel;
  final int rssiThreshold;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isActive;
  final String? className;
  final String? subjectName;

  const SessionModel({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.code,
    required this.securityLevel,
    required this.rssiThreshold,
    required this.startTime,
    this.endTime,
    required this.isActive,
    this.className,
    this.subjectName,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] as String? ?? '',
      teacherId: map['teacher_id'] as String? ?? '',
      classId: map['class_id'] as String? ?? '',
      subjectId: map['subject_id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      securityLevel: map['security_level'] as String? ?? 'LOW',
      rssiThreshold: (map['rssi_threshold'] as num?)?.toInt() ?? -70,
      startTime: map['start_time'] != null
          ? DateTime.parse(map['start_time'] as String)
          : DateTime.now(),
      endTime: map['end_time'] != null
          ? DateTime.parse(map['end_time'] as String)
          : null,
      isActive: map['is_active'] as bool? ?? false,
      className: map['class_name'] as String?,
      subjectName: map['subject_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'teacher_id': teacherId,
    'class_id': classId,
    'subject_id': subjectId,
    'code': code,
    'security_level': securityLevel,
    'rssi_threshold': rssiThreshold,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime?.toIso8601String(),
    'is_active': isActive,
  };

  Duration get elapsed => DateTime.now().difference(startTime);
}
