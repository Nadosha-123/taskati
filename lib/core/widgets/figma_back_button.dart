import 'package:flutter/material.dart';

class FigmaBackButton extends StatelessWidget {
  const FigmaBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        tooltip: 'Back',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        onPressed: onPressed,
        icon: CustomPaint(
          size: const Size.square(24),
          painter: _BackArrowPainter(
            Theme.of(context).colorScheme.onSurface,
            Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _BackArrowPainter extends CustomPainter {
  const _BackArrowPainter(this.color, this.textDirection);

  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (textDirection == TextDirection.rtl) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final paint = Paint()..color = color;
    final arrowhead = Path()
      ..moveTo(3, 12)
      ..lineTo(11, 5)
      ..lineTo(11, 19)
      ..close();
    canvas.drawPath(arrowhead, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(15, 10.5, 6, 3),
        const Radius.circular(1.5),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.textDirection != textDirection;
}
