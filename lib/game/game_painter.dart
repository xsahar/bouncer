
import 'package:flutter/material.dart';
import 'package:bouncer/models/brick.dart';

class GamePainter extends CustomPainter {
  final Offset ballPosition;
  final double paddleX;
  final List<Brick> bricks;

  GamePainter({
    required this.ballPosition,
    required this.paddleX,
    required this.bricks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ballPaint = Paint()..color = Colors.blueAccent;

    final paddlePaint = Paint()
      ..color = const Color.fromARGB(255, 206, 63, 63);

    final brickColors = [
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.greenAccent,
    ];

    // Draw the ball.
    canvas.drawCircle(
      ballPosition,
      10,
      ballPaint,
    );

    // Draw the paddle.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(paddleX, size.height * 0.9),
        width: 100,
        height: 12,
      ),
      paddlePaint,
    );

    // Draw the living bricks.
    for (int i = 0; i < bricks.length; i++) {
      final brick = bricks[i];

      if (!brick.isAlive) continue;

      final brickPaint = Paint()
        ..color = brickColors[
            (i ~/ 5) % brickColors.length];

      canvas.drawRect(
        brick.rect,
        brickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    // Repaint when the game state changes.
    return true;
  }
}
