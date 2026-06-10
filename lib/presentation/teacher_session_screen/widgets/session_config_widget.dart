import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/attendance_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card_widget.dart';

class SessionConfigWidget extends StatelessWidget {
  final List<ClassModel> classes;
  final List<SubjectModel> subjects;
  final List<AssignmentModel> assignments;
  final String? selectedClassId;
  final String? selectedSubjectId;
  final int durationSeconds;
  final String securityLevel;
  final int rssiThreshold;
  final void Function(String?) onClassChanged;
  final void Function(String?) onSubjectChanged;
  final void Function(int) onDurationChanged;
  final void Function(String) onSecurityLevelChanged;
  final void Function(int) onRssiThresholdChanged;

  const SessionConfigWidget({
    super.key,
    required this.classes,
    required this.subjects,
    required this.assignments,
    required this.selectedClassId,
    required this.selectedSubjectId,
    required this.durationSeconds,
    required this.securityLevel,
    required this.rssiThreshold,
    required this.onClassChanged,
    required this.onSubjectChanged,
    required this.onDurationChanged,
    required this.onSecurityLevelChanged,
    required this.onRssiThresholdChanged,
  });

  // Filter classes and subjects based on teacher assignments
  List<ClassModel> get _assignedClasses {
    if (assignments.isEmpty) return classes;
    final assignedClassIds = assignments.map((a) => a.classId).toSet();
    return classes.where((c) => assignedClassIds.contains(c.id)).toList();
  }

  List<SubjectModel> get _assignedSubjects {
    if (assignments.isEmpty) return subjects;
    if (selectedClassId == null) {
      final assignedSubjectIds = assignments.map((a) => a.subjectId).toSet();
      return subjects.where((s) => assignedSubjectIds.contains(s.id)).toList();
    }
    final assignedSubjectIds = assignments
        .where((a) => a.classId == selectedClassId)
        .map((a) => a.subjectId)
        .toSet();
    return subjects.where((s) => assignedSubjectIds.contains(s.id)).toList();
  }

  Color _securityColor(String level) {
    switch (level) {
      case 'HIGH':
        return AppTheme.success;
      case 'LOW':
        return AppTheme.warning;
      default:
        return AppTheme.warning;
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0 && s > 0) return '${m}m ${s}s';
    if (m > 0) return '${m}m';
    return '${s}s';
  }

  Widget _buildDurationSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Duration',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
                letterSpacing: 0.4,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(38),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(durationSeconds),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.shadowLight.withAlpha(25),
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withAlpha(38),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            valueIndicatorColor: AppTheme.primary,
            valueIndicatorTextStyle: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Slider(
            value: durationSeconds.toDouble(),
            min: 15,
            max: 300,
            divisions: 285,
            label: _formatDuration(durationSeconds),
            onChanged: (v) => onDurationChanged(v.toInt()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15s',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                '5m',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.tune_rounded,
            label: 'Session Configuration',
          ),
          const SizedBox(height: 20),
          _buildDropdown(
            label: 'Class',
            icon: Icons.class_outlined,
            value: selectedClassId,
            items: _assignedClasses
                .map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onClassChanged,
            hint: 'Select class',
          ),
          const SizedBox(height: 14),
          _buildDropdown(
            label: 'Subject',
            icon: Icons.book_outlined,
            value: selectedSubjectId,
            items: _assignedSubjects
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      s.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onSubjectChanged,
            hint: 'Select subject',
          ),
          const SizedBox(height: 20),
          _buildDurationSelector(context),
          const SizedBox(height: 20),
          _SectionHeader(
            icon: Icons.security_outlined,
            label: 'Security Level',
          ),
          const SizedBox(height: 12),
          Row(
            children: ['LOW', 'HIGH'].map((level) {
              final isSelected = securityLevel == level;
              final color = _securityColor(level);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: level == 'LOW' ? 8 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withAlpha(38)
                          : AppTheme.surface.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color.withAlpha(128)
                            : AppTheme.shadowLight.withAlpha(25),
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => onSecurityLevelChanged(level),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            level == 'HIGH'
                                ? Icons.bluetooth_searching_rounded
                                : Icons.pin_outlined,
                            color: isSelected ? color : AppTheme.textMuted,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            level,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (securityLevel == 'HIGH') ...[
            const SizedBox(height: 20),
            _SectionHeader(
              icon: Icons.signal_cellular_alt_rounded,
              label: 'RSSI Threshold: $rssiThreshold dBm',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '-100',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.shadowLight.withAlpha(25),
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withAlpha(38),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: rssiThreshold.toDouble(),
                      min: -100,
                      max: -30,
                      divisions: 70,
                      onChanged: (v) => onRssiThresholdChanged(v.toInt()),
                    ),
                  ),
                ),
                Text(
                  '-30',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Far',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface.withAlpha(13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.shadowLight.withAlpha(38),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  hint,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textDisabled,
                  ),
                ),
              ),
              isExpanded: true,
              dropdownColor: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.textMuted,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
