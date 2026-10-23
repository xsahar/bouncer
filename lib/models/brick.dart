
import 'package:flutter/material.dart';

class Brick {
  final Rect rect;
  bool isAlive;

  Brick({
    required this.rect,
    this.isAlive = true,
  });
}
