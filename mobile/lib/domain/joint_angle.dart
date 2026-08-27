import 'dart:math' as math;

class Point2 {
  const Point2(this.x, this.y);

  final double x;
  final double y;
}

double? jointAngle(Point2 start, Point2 vertex, Point2 end) {
  if (![
    start.x,
    start.y,
    vertex.x,
    vertex.y,
    end.x,
    end.y,
  ].every((v) => v.isFinite)) {
    return null;
  }
  final firstX = start.x - vertex.x;
  final firstY = start.y - vertex.y;
  final secondX = end.x - vertex.x;
  final secondY = end.y - vertex.y;
  final firstLength = math.sqrt(firstX * firstX + firstY * firstY);
  final secondLength = math.sqrt(secondX * secondX + secondY * secondY);
  if (firstLength == 0 || secondLength == 0) return null;

  final cosine =
      ((firstX * secondX + firstY * secondY) / (firstLength * secondLength))
          .clamp(-1.0, 1.0);
  return math.acos(cosine) * 180 / math.pi;
}
