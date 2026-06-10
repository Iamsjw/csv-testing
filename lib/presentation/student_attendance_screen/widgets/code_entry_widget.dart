import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CodeEntryWidget extends StatefulWidget {
  final void Function(String code) onCodeSubmit;
  final bool isLoading;
  final Animation<double> shakeAnimation;
  final bool hasError;

  const CodeEntryWidget({
    super.key,
    required this.onCodeSubmit,
    required this.isLoading,
    required this.shakeAnimation,
    required this.hasError,
  });

  @override
  State<CodeEntryWidget> createState() => _CodeEntryWidgetState();
}

class _CodeEntryWidgetState extends State<CodeEntryWidget> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String get _code => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < digits.length && i + index < 6; i++) {
        _controllers[index + i].text = digits[i];
      }
      final nextFocus = (index + digits.length).clamp(0, 5);
      _focusNodes[nextFocus].requestFocus();
    } else if (value.isNotEmpty) {
      _controllers[index].text = value;
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_code.length == 6) {
          widget.onCodeSubmit(_code);
        }
      }
    }
    setState(() {});
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.shakeAnimation,
      builder: (context, child) {
        final shakeOffset = widget.hasError
            ? 8.0 * (0.5 - (widget.shakeAnimation.value - 0.5).abs())
            : 0.0;
        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: Container(
        decoration: AppTheme.glassMorphism(
          borderRadius: BorderRadius.circular(20),
          opacity: widget.hasError ? 0.04 : 0.05,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.hasError
                    ? AppTheme.errorSoft
                    : AppTheme.surface.withAlpha(13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.hasError
                      ? AppTheme.error.withAlpha(77)
                      : AppTheme.shadowLight.withAlpha(25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withAlpha(38),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.pin_outlined,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Session Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Get the 6-digit code from your teacher',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // OTP digit boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final isFilled = _controllers[i].text.isNotEmpty;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i < 5 ? 8 : 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 56,
                            decoration: BoxDecoration(
                              color: isFilled
                                  ? AppTheme.primary.withAlpha(38)
                                  : AppTheme.surface.withAlpha(13),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isFilled
                                    ? AppTheme.primary.withAlpha(128)
                                    : AppTheme.shadowLight.withAlpha(25),
                                width: 1.5,
                              ),
                            ),
                            child: KeyboardListener(
                              focusNode: FocusNode(),
                              onKeyEvent: (e) => _onKeyDown(i, e),
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focusNodes[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) => _onDigitChanged(i, v),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  // Submit button
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: _code.length == 6
                                ? AppTheme.primaryGradient
                                : null,
                            color: _code.length < 6
                                ? AppTheme.surface.withAlpha(13)
                                : null,
                            border: Border.all(
                              color: _code.length == 6
                                  ? Colors.transparent
                                  : AppTheme.shadowLight.withAlpha(25),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (widget.isLoading || _code.length < 6)
                                  ? null
                                  : () => widget.onCodeSubmit(_code),
                              borderRadius: BorderRadius.circular(14),
                              child: Center(
                                child: widget.isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle_outline_rounded,
                                            color: _code.length == 6
                                                ? Colors.white
                                                : AppTheme.textDisabled,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Mark Attendance',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _code.length == 6
                                                  ? Colors.white
                                                  : AppTheme.textDisabled,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_code.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _clearCode,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withAlpha(13),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.shadowLight.withAlpha(25),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.backspace_outlined,
                              color: AppTheme.textMuted,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
