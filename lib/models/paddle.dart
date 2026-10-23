
class Paddle {
  double x;

  final double width;
  final double height;
  final double verticalPosition;

  Paddle({
    required this.x,
    this.width = 100,
    this.height = 12,
    this.verticalPosition = 0.9,
  });

  void moveBy(double distance, double gameWidth) {
    x = (x + distance)
        .clamp(width / 2, gameWidth - width / 2)
        .toDouble();
  }
}
