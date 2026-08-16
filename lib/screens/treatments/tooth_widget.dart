import 'package:flutter/material.dart';
import '../../core/constants/status_labels.dart';
import '../../theme/app_theme.dart';

class ToothWidget extends StatefulWidget {
  final int toothNumber;
  final String status; // 'healthy', 'planned', 'in_progress', 'completed'
  final bool isSelected;
  final bool isUpperArch;
  final VoidCallback onTap;

  const ToothWidget({
    super.key,
    required this.toothNumber,
    this.status = 'healthy',
    required this.isSelected,
    this.isUpperArch = true,
    required this.onTap,
  });

  @override
  State<ToothWidget> createState() => _ToothWidgetState();
}

class _ToothWidgetState extends State<ToothWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.status.toLowerCase();

    Color fillColor = Colors.white;
    Color borderColor = AppColors.border;
    Color accentColor = AppColors.textSecondary;

    if (status != 'healthy' && status.isNotEmpty) {
      fillColor = StatusLabels.treatmentStatusBgColor(status);
      borderColor = StatusLabels.treatmentStatusColor(status);
      accentColor = borderColor;
    }

    if (widget.isSelected) {
      borderColor = AppColors.primary;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 82,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.primaryLight : fillColor,
            borderRadius: AppRadius.borderRadiusLg,
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : borderColor,
              width: widget.isSelected ? 2.5 : _isHovered ? 1.8 : 1.2,
            ),
            boxShadow: [
              if (widget.isSelected || _isHovered)
                BoxShadow(
                  color: (widget.isSelected ? AppColors.primary : borderColor)
                      .withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.isUpperArch)
                _buildToothNumberTag(accentColor)
              else
                _buildAnatomicalTooth(accentColor),

              if (widget.isUpperArch)
                _buildAnatomicalTooth(accentColor)
              else
                _buildToothNumberTag(accentColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToothNumberTag(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: widget.isSelected ? AppColors.primary : AppColors.background,
        borderRadius: AppRadius.borderRadiusSm,
      ),
      child: Text(
        '${widget.toothNumber}',
        style: AppTypography.badgeSmall.copyWith(
          color: widget.isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAnatomicalTooth(Color accentColor) {
    final status = widget.status.toLowerCase();
    final hasTreatment = status != 'healthy' && status.isNotEmpty;

    return CustomPaint(
      size: const Size(36, 42),
      painter: _ToothPainter(
        toothNumber: widget.toothNumber,
        isUpperArch: widget.isUpperArch,
        accentColor: hasTreatment ? accentColor : AppColors.textMuted,
        isSelected: widget.isSelected,
      ),
    );
  }
}

class _ToothPainter extends CustomPainter {
  final int toothNumber;
  final bool isUpperArch;
  final Color accentColor;
  final bool isSelected;

  _ToothPainter({
    required this.toothNumber,
    required this.isUpperArch,
    required this.accentColor,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withValues(alpha: isSelected ? 0.9 : 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Distinguish Molars / Premolars vs Incisors / Canines based on FDI digit
    final lastDigit = toothNumber % 10;
    final isMolarOrPremolar = lastDigit >= 4;

    final path = Path();

    if (isUpperArch) {
      // Upper Arch: Roots at top, Crown at bottom
      if (isMolarOrPremolar) {
        // Multi-cusp crown
        path.moveTo(w * 0.2, h * 0.1);
        path.lineTo(w * 0.3, h * 0.45);
        path.lineTo(w * 0.1, h * 0.6);
        path.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.9, h * 0.6);
        path.lineTo(w * 0.7, h * 0.45);
        path.lineTo(w * 0.8, h * 0.1);
        path.close();
      } else {
        // Incisor / Canine shape
        path.moveTo(w * 0.5, h * 0.1);
        path.lineTo(w * 0.2, h * 0.5);
        path.lineTo(w * 0.2, h * 0.85);
        path.lineTo(w * 0.8, h * 0.85);
        path.lineTo(w * 0.8, h * 0.5);
        path.close();
      }
    } else {
      // Lower Arch: Crown at top, Roots at bottom
      if (isMolarOrPremolar) {
        path.moveTo(w * 0.1, h * 0.4);
        path.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.9, h * 0.4);
        path.lineTo(w * 0.7, h * 0.55);
        path.lineTo(w * 0.8, h * 0.9);
        path.lineTo(w * 0.5, h * 0.65);
        path.lineTo(w * 0.2, h * 0.9);
        path.lineTo(w * 0.3, h * 0.55);
        path.close();
      } else {
        path.moveTo(w * 0.2, h * 0.15);
        path.lineTo(w * 0.8, h * 0.15);
        path.lineTo(w * 0.8, h * 0.5);
        path.lineTo(w * 0.5, h * 0.9);
        path.lineTo(w * 0.2, h * 0.5);
        path.close();
      }
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Inner occlusal groove for molars
    if (isMolarOrPremolar) {
      final groovePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      final centerY = isUpperArch ? h * 0.65 : h * 0.35;
      canvas.drawLine(
        Offset(w * 0.35, centerY),
        Offset(w * 0.65, centerY),
        groovePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ToothPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.isSelected != isSelected;
  }
}
