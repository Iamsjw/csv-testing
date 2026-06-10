import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class GlassFormFieldWidget extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const GlassFormFieldWidget({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<GlassFormFieldWidget> createState() => _GlassFormFieldWidgetState();
}

class _GlassFormFieldWidgetState extends State<GlassFormFieldWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _glowAnimation;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOutCubic),
    );
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              // Dark shadow (bottom-right)
              BoxShadow(
                color: AppTheme.shadowDark.withAlpha(40),
                offset: const Offset(2, 2),
                blurRadius: 8,
              ),
              // Light shadow (top-left)
              BoxShadow(
                color: AppTheme.shadowLight.withAlpha(20),
                offset: const Offset(-2, -2),
                blurRadius: 8,
              ),
              // Glow on focus
              if (_isFocused)
                BoxShadow(
                  color: AppTheme.primaryCyan.withAlpha(
                    (0.3 * _glowAnimation.value * 255).round(),
                  ),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                validator: widget.validator,
                enabled: widget.enabled,
                maxLines: widget.maxLines,
                onChanged: widget.onChanged,
                onFieldSubmitted: widget.onSubmitted,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  filled: true,
                  fillColor: _isFocused
                      ? AppTheme.surfaceVariant
                      : AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryCyan.withAlpha(
                        (0.5 * _glowAnimation.value * 255).round(),
                      ),
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.error,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.error,
                      width: 1.5,
                    ),
                  ),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textDisabled,
                    fontSize: 14,
                  ),
                  errorStyle: GoogleFonts.plusJakartaSans(
                    color: AppTheme.error,
                    fontSize: 11,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
