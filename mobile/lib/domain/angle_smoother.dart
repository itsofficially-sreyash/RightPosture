class AngleSmoother {
  AngleSmoother({this.windowSize = 3}) : assert(windowSize.isOdd);

  final int windowSize;
  final List<double> _values = [];

  double? add(double value) {
    if (!value.isFinite) return null;
    _values.add(value);
    if (_values.length > windowSize) _values.removeAt(0);
    if (_values.length < windowSize) return null;
    final sorted = [..._values]..sort();
    return sorted[sorted.length ~/ 2];
  }

  void reset() => _values.clear();
}
