import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import '../onboarding/design_tokens.dart';

class PremiumTextField extends StatefulWidget {
  const PremiumTextField({
    super.key,
    this.label = '',
    required this.controller,
    required this.icon,
    this.hintText = '',
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField>
    with TickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _focusController;
  late final AnimationController _shakeController;
  
  bool _isFocused = false;
  bool _obscureText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _focusController.dispose();
    _shakeController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _focusController.forward();
    } else {
      _focusController.reverse();
      _validate();
    }
  }

  void _onTextChanged() {
    if (_errorText != null) {
      _validate();
    }
  }

  void _validate() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      if (error != _errorText) {
        setState(() {
          _errorText = error;
        });
        if (error != null) {
          _shakeController.forward(from: 0.0);
          HapticFeedback.lightImpact();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _errorText != null;
    final errorColor = const Color(0xFFFF5A5F);

    return AnimatedBuilder(
      animation: Listenable.merge([_focusController, _shakeController]),
      builder: (context, child) {
        final focusAnim = _focusController.value;
        final shake = _shakeController.value;
        // Dampened sine wave for shake
        final offset = sin(shake * 4 * 3.14159) * 8 * (1 - shake);

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label (only shown if provided)
              if (widget.label.isNotEmpty) ...[
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: hasError
                        ? errorColor
                        : Color.lerp(
                            OBTokens.textMuted,
                            Colors.white,
                            focusAnim,
                          )!,
                  ),
                  child: Text(widget.label.toUpperCase()),
                ),
                const SizedBox(height: 8),
              ],

              // Input Container
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  // Background is always fixed (white 5% or 0x141418-ish)
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: hasError
                        ? errorColor
                        : _isFocused
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                    width: _isFocused || hasError ? 1.5 : 1.0,
                  ),
                  boxShadow: _isFocused && !hasError
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.05),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      widget.icon,
                      color: hasError
                          ? errorColor
                          : Color.lerp(
                              OBTokens.textMuted,
                              Colors.white,
                              focusAnim,
                            )!,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        obscureText: _obscureText,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        autofillHints: widget.autofillHints,
                        onFieldSubmitted: widget.onFieldSubmitted,
                        cursorColor: Colors.white,
                        cursorWidth: 2.0,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          hintStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (widget.isPassword)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: OBTokens.textMuted,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                  ],
                ),
              ),

              // Error Text
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: hasError
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: errorColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
