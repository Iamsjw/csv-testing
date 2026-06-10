import 'dart:convert' show utf8;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';


import '../models/attendance_model.dart';
import '../models/session_model.dart';
import '../theme/app_theme.dart';

class CsvExportService {
  static String _escapeCsvField(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().trim();
    return '"${str.replaceAll('"', '""')}"';
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  static String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m ${s}s';
  }

  static String generateCsv({
    required String subjectName,
    required String className,
    required SessionModel session,
    required List<AttendanceModel> attendance,
  }) {
    final buffer = StringBuffer();
    final presentCount = attendance.where((a) => a.isPresent).length;
    final revokedCount = attendance.where((a) => a.isRevoked).length;
    final totalStudents = attendance.length;
    final rate = totalStudents == 0 ? 0.0 : (presentCount / totalStudents) * 100;

    // Header
    buffer.writeln('UpasthitiX Attendance Report');
    buffer.writeln('');

    // Session details
    buffer.writeln('SESSION DETAILS');
    buffer.writeln('Subject,${_escapeCsvField(subjectName)}');
    buffer.writeln('Class,${_escapeCsvField(className)}');
    buffer.writeln('Date,${_formatDate(session.startTime)}');
    buffer.writeln('Start Time,${_formatTime(session.startTime)}');
    buffer.writeln(
      'End Time,${session.endTime != null ? _formatTime(session.endTime!) : "N/A"}',
    );
    buffer.writeln(
      'Duration,${_formatDuration(session.endTime != null ? session.endTime!.difference(session.startTime) : Duration.zero)}',
    );
    buffer.writeln('Session Code,${_escapeCsvField(session.code)}');
    buffer.writeln('Security Level,${_escapeCsvField(session.securityLevel)}');
    buffer.writeln('');

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Present,$presentCount');
    buffer.writeln('Revoked,$revokedCount');
    buffer.writeln('Total Records,$totalStudents');
    buffer.writeln('Attendance Rate,${rate.toStringAsFixed(1)}%');
    buffer.writeln('');

    // Attendance records
    buffer.writeln('ATTENDANCE RECORDS');
    buffer.writeln('No.,Student Name,Email,Status,Timestamp');
    for (var i = 0; i < attendance.length; i++) {
      final a = attendance[i];
      final status = a.isPresent
          ? 'Present'
          : (a.isRevoked ? 'Revoked' : (a.status.isEmpty ? 'Unknown' : a.status));
      final ts =
          '${_formatDate(a.timestamp)} ${_formatTime(a.timestamp)}';
      buffer.writeln(
        '${i + 1},${_escapeCsvField(a.studentName ?? 'Unknown')},${_escapeCsvField(a.studentEmail ?? 'N/A')},${_escapeCsvField(status)},${_escapeCsvField(ts)}',
      );
    }

    return buffer.toString();
  }

  static Future<void> downloadCsv({
    required BuildContext context,
    required String subjectName,
    required String className,
    required SessionModel session,
    required List<AttendanceModel> attendance,
  }) async {
    try {
      final csvContent = generateCsv(
        subjectName: subjectName,
        className: className,
        session: session,
        attendance: attendance,
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'attendance_${_sanitizeFileName(subjectName)}_${_sanitizeFileName(className)}_$timestamp.csv';

      if (kIsWeb) {
        _downloadWeb(csvContent, fileName);
        _showSuccessSnackBar(context, fileName);
      } else {
        _showCsvPreview(context, csvContent, fileName);
      }
    } catch (e) {
      _showErrorSnackBar(context, e);
    }
  }

  static Future<void> downloadCsvFromMap({
    required BuildContext context,
    required Map<String, dynamic> sessionData,
    required List<Map<String, dynamic>> attendanceData,
  }) async {
    try {
      final csvContent = _generateCsvFromMap(sessionData, attendanceData);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final subjectName =
          (sessionData['subjects'] as Map?)?['name'] ?? 'Unknown';
      final className =
          (sessionData['classes'] as Map?)?['name'] ?? 'Unknown';
      final fileName =
          'attendance_${_sanitizeFileName(subjectName)}_${_sanitizeFileName(className)}_$timestamp.csv';

      if (kIsWeb) {
        _downloadWeb(csvContent, fileName);
        _showSuccessSnackBar(context, fileName);
      } else {
        _showCsvPreview(context, csvContent, fileName);
      }
    } catch (e) {
      _showErrorSnackBar(context, e);
    }
  }

  static String _generateCsvFromMap(
    Map<String, dynamic> session,
    List<Map<String, dynamic>> attendance,
  ) {
    final buffer = StringBuffer();
    final subjectName =
        (session['subjects'] as Map?)?['name'] ?? 'Unknown';
    final className =
        (session['classes'] as Map?)?['name'] ?? 'Unknown';
    final code = session['code'] as String? ?? '';
    final securityLevel = session['security_level'] as String? ?? 'LOW';
    final startTime = session['start_time'] != null
        ? DateTime.parse(session['start_time'] as String)
        : DateTime.now();
    final endTime = session['end_time'] != null
        ? DateTime.parse(session['end_time'] as String)
        : null;

    final presentCount =
        attendance.where((a) => a['status'] == 'present').length;
    final revokedCount =
        attendance.where((a) => a['status'] == 'revoked').length;
    final totalStudents = attendance.length;
    final rate = totalStudents == 0
        ? 0.0
        : (presentCount / totalStudents) * 100;

    // Header
    buffer.writeln('UpasthitiX Attendance Report');
    buffer.writeln('');

    // Session details
    buffer.writeln('SESSION DETAILS');
    buffer.writeln('Subject,${_escapeCsvField(subjectName)}');
    buffer.writeln('Class,${_escapeCsvField(className)}');
    buffer.writeln('Date,${_formatDate(startTime)}');
    buffer.writeln('Start Time,${_formatTime(startTime)}');
    buffer.writeln(
      'End Time,${endTime != null ? _formatTime(endTime) : "N/A"}',
    );
    buffer.writeln(
      'Duration,${_formatDuration(endTime != null ? endTime.difference(startTime) : Duration.zero)}',
    );
    buffer.writeln('Session Code,${_escapeCsvField(code)}');
    buffer.writeln('Security Level,${_escapeCsvField(securityLevel)}');
    buffer.writeln('');

    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Present,$presentCount');
    buffer.writeln('Revoked,$revokedCount');
    buffer.writeln('Total Records,$totalStudents');
    buffer.writeln('Attendance Rate,${rate.toStringAsFixed(1)}%');
    buffer.writeln('');

    // Attendance records
    buffer.writeln('ATTENDANCE RECORDS');
    buffer.writeln('No.,Student Name,Email,Status,Timestamp');
    for (var i = 0; i < attendance.length; i++) {
      final a = attendance[i];
      final name = a['users']?['name'] ?? 'Unknown';
      final email = a['users']?['email'] ?? 'N/A';
      final status = a['status'] == 'present'
          ? 'Present'
          : (a['status'] == 'revoked' ? 'Revoked' : (a['status'] ?? 'Unknown'));
      final ts = a['timestamp'] != null
          ? '${_formatDate(DateTime.parse(a['timestamp'] as String))} ${_formatTime(DateTime.parse(a['timestamp'] as String))}'
          : 'N/A';
      buffer.writeln(
        '${i + 1},${_escapeCsvField(name)},${_escapeCsvField(email)},${_escapeCsvField(status)},${_escapeCsvField(ts)}',
      );
    }

    return buffer.toString();
  }

  static Future<void> downloadAdminReportCsv({
    required BuildContext context,
    required String className,
    required List<dynamic> records,
  }) async {
    try {
      final csvContent = _generateAdminReportCsv(className, records);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'attendance_report_${_sanitizeFileName(className)}_$timestamp.csv';

      if (kIsWeb) {
        _downloadWeb(csvContent, fileName);
        _showSuccessSnackBar(context, fileName);
      } else {
        _showCsvPreview(context, csvContent, fileName);
      }
    } catch (e) {
      _showErrorSnackBar(context, e);
    }
  }

  static String _generateAdminReportCsv(
    String className,
    List<dynamic> records,
  ) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('UpasthitiX Attendance Report');
    buffer.writeln('');

    // Class details
    buffer.writeln('CLASS DETAILS');
    buffer.writeln('Class,${_escapeCsvField(className)}');
    buffer.writeln('Generated At,${_formatDate(DateTime.now())} ${_formatTime(DateTime.now())}');
    buffer.writeln('');

    // Summary
    final total = records.length;
    final presentCount = records.where((r) => r['status'] == 'present').length;
    final rate = total == 0 ? 0.0 : (presentCount / total) * 100;

    buffer.writeln('SUMMARY');
    buffer.writeln('Total Records,$total');
    buffer.writeln('Present,$presentCount');
    buffer.writeln('Attendance Rate,${rate.toStringAsFixed(1)}%');
    buffer.writeln('');

    // Attendance records
    buffer.writeln('ATTENDANCE RECORDS');
    buffer.writeln('No.,Student Name,Email,Subject,Status,Timestamp');
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final name = r['users']?['name'] ?? 'Unknown';
      final email = r['users']?['email'] ?? 'N/A';
      final subject = r['sessions']?['subjects']?['name'] ?? 'Unknown';
      final status = r['status'] == 'present'
          ? 'Present'
          : (r['status'] == 'revoked' ? 'Revoked' : (r['status'] ?? 'Unknown'));
      final ts = r['timestamp'] != null
          ? '${_formatDate(DateTime.parse(r['timestamp'] as String))} ${_formatTime(DateTime.parse(r['timestamp'] as String))}'
          : 'N/A';

      buffer.writeln(
        '${i + 1},${_escapeCsvField(name)},${_escapeCsvField(email)},${_escapeCsvField(subject)},${_escapeCsvField(status)},${_escapeCsvField(ts)}',
      );
    }

    return buffer.toString();
  }

  static void _downloadWeb(String csvContent, String fileName) {
    final blob = html.Blob(['\uFEFF', csvContent], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static void _showCsvPreview(
    BuildContext context,
    String csvContent,
    String fileName,
  ) {
    final report = _parseCsv(csvContent);
    final isAdminReport = report.headers.contains('Subject');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(26),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report Preview',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          fileName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report.details.isNotEmpty) ...[
                        _buildSectionHeader('Details'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.shadowLight.withAlpha(25),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: report.details.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      e.key,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      e.value,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (report.summary.isNotEmpty) ...[
                        _buildSectionHeader('Summary'),
                        const SizedBox(height: 8),
                        Row(
                          children: report.summary.entries.map((e) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.primary.withAlpha(15),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      e.key,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      e.value,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryCyan,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildSectionHeader('Attendance Records (${report.records.length})'),
                      const SizedBox(height: 8),
                      if (report.records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No records found.',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: report.records.length,
                          itemBuilder: (context, idx) {
                            final record = report.records[idx];
                            if (record.length < 4) return const SizedBox.shrink();

                            final name = record[1];
                            final email = record[2];
                            
                            final String status;
                            final String extra;
                            final bool isPresent;

                            if (isAdminReport && record.length >= 6) {
                              final subject = record[3];
                              status = record[4];
                              extra = 'Subject: $subject | ${record[5]}';
                              isPresent = status.toLowerCase() == 'present';
                            } else {
                              status = record[3];
                              extra = record[4];
                              isPresent = status.toLowerCase() == 'present';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.shadowLight.withAlpha(15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      record[0],
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          extra,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: AppTheme.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPresent ? AppTheme.successSoft : AppTheme.errorSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: isPresent ? AppTheme.success : AppTheme.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.textSecondary.withAlpha(50), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Close',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Icon(
                        Icons.copy_all_rounded,
                        color: AppTheme.primary,
                        size: 16,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: csvContent));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'CSV copied to clipboard!',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12),
                            ),
                            backgroundColor: AppTheme.successSoft,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      label: Text(
                        'Copy',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () async {
                        try {
                          final tempDir = await getTemporaryDirectory();
                          final file = File('${tempDir.path}/$fileName');
                          await file.writeAsString(csvContent, encoding: utf8);
                          await Share.shareXFiles(
                            [XFile(file.path)],
                            subject: fileName,
                          );
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Failed to share: $e'),
                                backgroundColor: AppTheme.errorSoft,
                              ),
                            );
                          }
                        }
                      },
                      label: Text(
                        'Share/Save',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  static _PreviewReport _parseCsv(String csvContent) {
    final lines = csvContent.split('\n');
    String title = 'Attendance Report';
    final details = <String, String>{};
    final summary = <String, String>{};
    final headers = <String>[];
    final records = <List<String>>[];

    String section = '';

    List<String> parseFields(String line) {
      final fields = <String>[];
      final buffer = StringBuffer();
      bool inQuotes = false;
      for (int i = 0; i < line.length; i++) {
        final c = line[i];
        if (c == '"') {
          inQuotes = !inQuotes;
        } else if (c == ',' && !inQuotes) {
          fields.add(buffer.toString().trim());
          buffer.clear();
        } else {
          buffer.write(c);
        }
      }
      fields.add(buffer.toString().trim());
      return fields;
    }

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('UpasthitiX')) {
        title = line;
        continue;
      }

      if (line == 'SESSION DETAILS' || line == 'CLASS DETAILS') {
        section = 'DETAILS';
        continue;
      } else if (line == 'SUMMARY') {
        section = 'SUMMARY';
        continue;
      } else if (line == 'ATTENDANCE RECORDS') {
        section = 'RECORDS';
        continue;
      }

      final fields = parseFields(line);
      if (fields.isEmpty) continue;

      if (section == 'DETAILS') {
        if (fields.length >= 2) {
          details[fields[0]] = fields[1];
        }
      } else if (section == 'SUMMARY') {
        if (fields.length >= 2) {
          summary[fields[0]] = fields[1];
        }
      } else if (section == 'RECORDS') {
        if (headers.isEmpty) {
          headers.addAll(fields);
        } else {
          records.add(fields);
        }
      }
    }

    return _PreviewReport(
      title: title,
      details: details,
      summary: summary,
      headers: headers,
      records: records,
    );
  }

  static void _showSuccessSnackBar(BuildContext context, String fileName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'CSV downloaded: $fileName',
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
        ),
        backgroundColor: AppTheme.successSoft,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to download CSV: $e',
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
        ),
        backgroundColor: AppTheme.errorSoft,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _PreviewReport {
  final String title;
  final Map<String, String> details;
  final Map<String, String> summary;
  final List<String> headers;
  final List<List<String>> records;

  _PreviewReport({
    required this.title,
    required this.details,
    required this.summary,
    required this.headers,
    required this.records,
  });
}

