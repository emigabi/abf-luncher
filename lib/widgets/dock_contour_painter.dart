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

import 'package:flutter/material.dart';

/// Paints the 1dp specular gradient contour along the dock container's perimeter.
///
/// Ported from the native Arc TV dock (`LauncherDock.kt` / `Dock.kt:378`):
/// A 1dp line falling away from the top edge (`White @ 0.25` -> `White @ 0.10` at 40% ->
/// `White @ 0.04` at 100%), which reads as light catching a bevel rather than as a heavy
/// solid frame.
class DockContourPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;

  static const LinearGradient contourGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.4, 1.0],
    colors: [
      Color(0x40FFFFFF), // White @ 0.25
      Color(0x1AFFFFFF), // White @ 0.10
      Color(0x0AFFFFFF), // White @ 0.04
    ],
  );

  const DockContourPainter({
    this.radius = 24.0,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || strokeWidth <= 0) return;

    final halfStroke = strokeWidth / 2.0;
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

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = contourGradient.createShader(Offset.zero & size);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant DockContourPainter oldDelegate) =>
      oldDelegate.radius != radius || oldDelegate.strokeWidth != strokeWidth;
}
