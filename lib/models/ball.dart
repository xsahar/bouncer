
import 'package:flutter/material.dart';
import 'paddle.dart';

class Ball {
  double x;
  double y;

  double velocityX;
  double velocityY;

  final double radius;

  Ball({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    this.radius = 10,
  });

  void update({
    required double dt,
    required Size gameSize,
    required Paddle paddle,
  }) {
    // Move the ball.
    x += velocityX * dt;
    y += velocityY * dt;

    // Bounce off the left wall.
    if (x - radius <= 0) {
      x = radius;
      velocityX = velocityX.abs();
    }
    // Bounce off the right wall.
    else if (x + radius >= gameSize.width) {
      x = gameSize.width - radius;
      velocityX = -velocityX.abs();
    }

    // Bounce off the top wall.
    if (y - radius <= 0) {
      y = radius;
      velocityY = velocityY.abs();
    }

    // Calculate paddle boundaries.
    final paddleLeft = paddle.x - paddle.width / 2;
    final paddleRight = paddle.x + paddle.width / 2;

    final paddleTop =
        gameSize.height * paddle.verticalPosition -
        paddle.height / 2;

    // Detect collision with the paddle.
    if (velocityY > 0 &&
        y + radius >= paddleTop &&
        y - radius < paddleTop &&
        x + radius >= paddleLeft &&
        x - radius <= paddleRight) {
      y = paddleTop - radius;
      velocityY = -velocityY.abs();
    }
  }
}
