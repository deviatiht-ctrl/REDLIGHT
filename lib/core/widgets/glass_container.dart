import 'dart:ui';

import 'package:flutter/material.dart';

/// Kontenè glassmorphic — blur + transparan + border subtil.
/// Itilize pou nav bar, modal, bottom sheets, bouton aksyon.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 20,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                color ??
                (isDark
                    ? const Color.fromRGBO(20, 20, 20, 0.6)
                    : const Color.fromRGBO(255, 255, 255, 0.72)),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color:
                  borderColor ??
                  (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06)),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
