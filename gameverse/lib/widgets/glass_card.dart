import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.boxShadow,
    this.gradient,
    this.onTap,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    Widget inner = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient ?? LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (enableBlur) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: inner,
        ),
      );
    }

    return inner;
  }
}
