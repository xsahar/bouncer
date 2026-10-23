
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:bouncer/game/game_painter.dart';
import 'package:bouncer/models/ball.dart';
import 'package:bouncer/models/paddle.dart';
import 'package:bouncer/models/brick.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final Ticker _ticker;

  Size _gameSize = Size.zero;
  Duration? _lastElapsed;

  final Ball _ball = Ball(
    x: 100,
    y: 150,
    velocityX: 120,
    velocityY: 160,
  );

  final Paddle _paddle = Paddle(x: 0);
  final List<Brick> _bricks = [];

  bool _hasInitializedPaddle = false;
  bool _gameOver = false;
  bool _won = false;

  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription;

  double _smoothedTilt = 0;

  @override
  void initState() {
    super.initState();

    _ticker = Ticker(_updateBall);
    _ticker.start();

    _accelerometerSubscription =
        accelerometerEventStream().listen(
      (event) {
        if (_gameSize.width <= 100 || _gameOver) return;

        // Smooth sensor readings.
        _smoothedTilt =
            (_smoothedTilt * 0.5) + (event.x * 0.5);

        // Ignore tiny movements.
        const deadZone = 0.8;
        if (_smoothedTilt.abs() < deadZone) return;

        if (!mounted) return;

        setState(() {
          _paddle.moveBy(
            -_smoothedTilt * 16,
            _gameSize.width,
          );
        });
      },
      onError: (error) {
        debugPrint('Accelerometer error: $error');
      },
    );
  }


void _updateBall(Duration elapsed) {
  final previous = _lastElapsed;
  _lastElapsed = elapsed;

  if (previous == null ||
      _gameSize == Size.zero ||
      _gameOver) {
    return;
  }

  final dt =
      (elapsed - previous).inMicroseconds / 1000000;

  if (!mounted) return;

  final previousX = _ball.x;
  final previousY = _ball.y;

  setState(() {
    // Move the ball and handle wall/paddle collisions.
    _ball.update(
      dt: dt,
      gameSize: _gameSize,
      paddle: _paddle,
    );

    // Check brick collisions AFTER moving the ball.
    _checkBrickCollisions(previousX, previousY);

    // Check win and lose conditions.
    if (_bricks.every((brick) => !brick.isAlive)) {
      _gameOver = true;
      _won = true;
    } else if (_ball.y - _ball.radius > _gameSize.height) {
      _gameOver = true;
      _won = false;
    }
  });
}


void _checkBrickCollisions(
  double previousX,
  double previousY,
) {
  final dx = _ball.x - previousX;
  final dy = _ball.y - previousY;
  final radius = _ball.radius;

  for (final brick in _bricks) {
    if (!brick.isAlive) continue;

    final rect = brick.rect;

    // Expand the brick by the ball's radius.
    // This lets us check the ball's center against it.
    final expandedRect = Rect.fromLTRB(
      rect.left - radius,
      rect.top - radius,
      rect.right + radius,
      rect.bottom + radius,
    );

    final currentPosition = Offset(_ball.x, _ball.y);

    if (!expandedRect.contains(currentPosition)) {
      continue;
    }

    if (dx == 0 && dy == 0) continue;

    double xEntry;
    double xExit;
    double yEntry;
    double yExit;

    // Find when the ball enters and exits horizontally.
    if (dx > 0) {
      xEntry = (expandedRect.left - previousX) / dx;
      xExit = (expandedRect.right - previousX) / dx;
    } else if (dx < 0) {
      xEntry = (expandedRect.right - previousX) / dx;
      xExit = (expandedRect.left - previousX) / dx;
    } else {
      xEntry = double.negativeInfinity;
      xExit = double.infinity;
    }

    // Find when the ball enters and exits vertically.
    if (dy > 0) {
      yEntry = (expandedRect.top - previousY) / dy;
      yExit = (expandedRect.bottom - previousY) / dy;
    } else if (dy < 0) {
      yEntry = (expandedRect.bottom - previousY) / dy;
      yExit = (expandedRect.top - previousY) / dy;
    } else {
      yEntry = double.negativeInfinity;
      yExit = double.infinity;
    }

    final entryTime =
        xEntry > yEntry ? xEntry : yEntry;
    final exitTime =
        xExit < yExit ? xExit : yExit;

    // Ignore collisions outside this movement step.
    if (entryTime > exitTime ||
        exitTime < 0 ||
        entryTime > 1) {
      continue;
    }

    // The axis entered last identifies the impact side.
    if (xEntry > yEntry) {
      // Left or right side of the brick.
      _ball.velocityX = -_ball.velocityX;

      _ball.x = dx > 0
          ? rect.left - radius
          : rect.right + radius;
    } else {
      // Top or bottom of the brick.
      _ball.velocityY = -_ball.velocityY;

      _ball.y = dy > 0
          ? rect.top - radius
          : rect.bottom + radius;
    }

    brick.isAlive = false;
    break;
  }
}

  void _createBricks() {
    const int columns = 5;
    const int rows = 3;
    const double brickHeight = 22;
    const double spacing = 6;
    const double sideMargin = 16;
    const double topMargin = 30;

    final brickWidth =
        (_gameSize.width -
            (sideMargin * 2) -
            (spacing * (columns - 1))) /
        columns;

    _bricks.clear();

    for (int row = 0; row < rows; row++) {
      for (int column = 0; column < columns; column++) {
        final left =
            sideMargin + column * (brickWidth + spacing);
        final top =
            topMargin + row * (brickHeight + spacing);

        _bricks.add(
          Brick(
            rect: Rect.fromLTWH(
              left,
              top,
              brickWidth,
              brickHeight,
            ),
          ),
        );
      }
    }
  }

  void _restartGame() {
    setState(() {
      _ball.x = _gameSize.width / 2;
      _ball.y = _gameSize.height * 0.6;
      _ball.velocityX = 120;
      _ball.velocityY = 160;

      _paddle.x = _gameSize.width / 2;

      _gameOver = false;
      _won = false;
      _smoothedTilt = 0;
      _lastElapsed = null;

      _createBricks();
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bouncer'),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        color: Colors.black87,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _gameSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            if (!_hasInitializedPaddle &&
                _gameSize.width > 100) {
              _paddle.x = _gameSize.width / 2;
              _hasInitializedPaddle = true;
            }

            if (_bricks.isEmpty &&
                _gameSize.width > 100) {
              _createBricks();
            }

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_gameOver) return;

                setState(() {
                  _paddle.moveBy(
                    details.delta.dx,
                    _gameSize.width,
                  );
                });
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GamePainter(
                        ballPosition: Offset(
                          _ball.x,
                          _ball.y,
                        ),
                        paddleX: _paddle.x,
                        bricks: _bricks,
                      ),
                    ),
                  ),

                  if (_gameOver)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: 0.75,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _won ? 'You Win!' : 'Game Over',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _restartGame,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Restart'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
