/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/launcher_state.dart';
import '../providers/settings_service.dart';

/// A focusable and hoverable capsule control for the top bar (Settings, Network, etc.),
/// ported from the native Arc TV design (`LauncherAppBar.kt` FocusRing).
///
/// Design attributes matching native Arc TV:
/// - Capsule/stadium shape (`RoundedCornerShape(percent = 50)`).
/// - Scale animation: 1.0 (rest) -> 1.08 (hover/focus) -> 0.92 (pressed) over 150ms.
/// - Translucent background: Transparent -> White @ 0.16 (hover) -> White @ 0.22 (focus) -> White @ 0.28 (pressed).
/// - Specular hairline gradient contour:
///   - Focused (1.0dp): White @ 0.65 -> Accent @ 0.50 -> White @ 0.35.
///   - Hovered (0.75dp): White @ 0.35 -> White @ 0.15.
///   - Pressed (0.75dp): White @ 0.45 -> White @ 0.25.
/// - Performance: pure vector drawing without offscreen blur filters or layers.
class AppBarFocusRing extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  const AppBarFocusRing({
    super.key,
    required this.child,
    required this.onPressed,
    this.focusNode,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    this.semanticLabel,
  });

  @override
  State<AppBarFocusRing> createState() => _AppBarFocusRingState();
}

class _AppBarFocusRingState extends State<AppBarFocusRing> {
  bool _isFocused = false;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accentColorHex = context.select<SettingsService, String>((s) => s.accentColorHex);
    final accentColor = Color(int.parse('FF$accentColorHex', radix: 16));

    final isHighlighted = _isFocused || _isHovered;
    final targetScale = _isPressed ? 0.92 : (isHighlighted ? 1.08 : 1.0);
    final targetProgress = isHighlighted || _isPressed ? 1.0 : 0.0;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onPressed()),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(onInvoke: (_) => widget.onPressed()),
        },
        child: Focus(
          focusNode: widget.focusNode,
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              context.read<LauncherState>().setAppGridFocused(false);
            }
            if (mounted) {
              setState(() => _isFocused = hasFocus);
            }
          },
          child: AnimatedScale(
            scale: targetScale,
            duration: const Duration(milliseconds: 150),
            curve: Curves.fastOutSlowIn,
            child: InkWell(
              onTap: widget.onPressed,
              onHover: (hovering) {
                if (mounted && _isHovered != hovering) {
                  setState(() => _isHovered = hovering);
                }
              },
              onHighlightChanged: (pressed) {
                if (mounted && _isPressed != pressed) {
                  setState(() => _isPressed = pressed);
                }
              },
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              customBorder: const StadiumBorder(),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: targetProgress),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) {
                  return CustomPaint(
                    painter: AppBarFocusRingPainter(
                      accentColor: accentColor,
                      isFocused: _isFocused,
                      isHovered: _isHovered,
                      isPressed: _isPressed,
                      progress: progress,
                    ),
                    child: child,
                  );
                },
                child: Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the capsule background tint and specular hairline gradient contour.
class AppBarFocusRingPainter extends CustomPainter {
  final Color accentColor;
  final bool isFocused;
  final bool isHovered;
  final bool isPressed;
  final double progress;

  const AppBarFocusRingPainter({
    required this.accentColor,
    required this.isFocused,
    required this.isHovered,
    required this.isPressed,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || progress <= 0.0) return;

    final double strokeWidth = isFocused ? 1.0 : 0.75;
    final double halfStroke = strokeWidth / 2.0;
    final double radius = min(size.width, size.height) / 2.0;

    final rect = Rect.fromLTWH(
      halfStroke,
      halfStroke,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular((radius - halfStroke).clamp(0.0, double.infinity)),
    );

    // 1. Translucent capsule fill
    final double baseBgAlpha;
    if (isPressed) {
      baseBgAlpha = 0.28;
    } else if (isFocused) {
      baseBgAlpha = 0.22;
    } else {
      baseBgAlpha = 0.16;
    }

    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: (baseBgAlpha * progress).clamp(0.0, 1.0));
    canvas.drawRRect(rrect, bgPaint);

    // 2. Specular hairline gradient contour
    final Gradient borderGradient;
    if (isFocused) {
      borderGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 1.0],
        colors: [
          Colors.white.withValues(alpha: (0.65 * progress).clamp(0.0, 1.0)),
          accentColor.withValues(alpha: (0.50 * progress).clamp(0.0, 1.0)),
          Colors.white.withValues(alpha: (0.35 * progress).clamp(0.0, 1.0)),
        ],
      );
    } else if (isPressed) {
      borderGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: (0.45 * progress).clamp(0.0, 1.0)),
          Colors.white.withValues(alpha: (0.25 * progress).clamp(0.0, 1.0)),
        ],
      );
    } else {
      // Hovered
      borderGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: (0.35 * progress).clamp(0.0, 1.0)),
          Colors.white.withValues(alpha: (0.15 * progress).clamp(0.0, 1.0)),
        ],
      );
    }

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = borderGradient.createShader(Offset.zero & size);

    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant AppBarFocusRingPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor ||
      oldDelegate.isFocused != isFocused ||
      oldDelegate.isHovered != isHovered ||
      oldDelegate.isPressed != isPressed ||
      oldDelegate.progress != progress;
}
