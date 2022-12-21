import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

// starts at the 2pm marker on an analog watch
const _kProgressBarStartingPoint = math.pi * (-1 / 2 + 1 / 3);
// finishes at the 4pm marker on an analog watch
const _kProgressBarLength = math.pi / 3;

class RoundScrollbar extends StatefulWidget {
  /// ScrollController for the scrollbar.
  final ScrollController controller;

  /// Padding between edges of screen and scrollbar track.
  final double padding;

  /// Width of scrollbar track and thumb.
  final double width;

  /// Whether scrollbar should hide automatically if inactive.
  final bool autoHide;

  /// Animation curve for the showing/hiding animation.
  final Curve opacityAnimationCurve;

  /// Animation duration for the showing/hiding animation.
  final Duration opacityAnimationDuration;

  /// How long scrollbar is displayed after a scroll event.
  final Duration autoHideDuration;

  /// Overrides color of the scrollbar track.
  final Color? trackColor;

  /// Overrides color of the scrollbar thumb.
  final Color? thumbColor;

  /// A scrollbar which curves around circular screens.
  /// Similar to native wearOS scrollbar in devices with round screens.
  const RoundScrollbar({
    required this.controller,
    this.padding = 8,
    this.width = 8,
    this.autoHide = true,
    this.opacityAnimationCurve = Curves.easeInOut,
    this.opacityAnimationDuration = const Duration(milliseconds: 250),
    this.autoHideDuration = const Duration(seconds: 3),
    this.trackColor,
    this.thumbColor,
    super.key,
  });

  @override
  State<RoundScrollbar> createState() => _RoundScrollbarState();
}

class _RoundScrollbarState extends State<RoundScrollbar> {
  double? _index;
  double? _fractionOfThumb;

  bool _isScrollBarVisible = true;

  void _onScrolled() {
    if (!widget.controller.hasClients) return;

    setState(() {
      _isScrollBarVisible = true;
      _updateScrollValues();
    });

    _hideAfterDelay();
  }

  int _currentHideUpdate = 0;

  void _hideAfterDelay() {
    if (!widget.autoHide) return;

    _currentHideUpdate++;
    final thisUpdate = _currentHideUpdate;
    Future.delayed(
      widget.autoHideDuration,
      () {
        if (thisUpdate != _currentHideUpdate) return;
        setState(() => _isScrollBarVisible = false);
      },
    );
  }

  void _updateScrollValues() {
    _fractionOfThumb = 1 /
        ((widget.controller.position.maxScrollExtent /
                widget.controller.position.viewportDimension) +
            1);

    _index = (widget.controller.offset /
        widget.controller.position.viewportDimension);
  }

  @override
  void initState() {
    widget.controller.addListener(_onScrolled);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollValues());
    WidgetsBinding.instance.addPostFrameCallback((_) => _hideAfterDelay());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrolled);
    super.dispose();
  }

  Widget _addAnimatedOpacity({required Widget child}) {
    if (!widget.autoHide) return child;

    return AnimatedOpacity(
      opacity: _isScrollBarVisible ? 1 : 0,
      duration: widget.opacityAnimationDuration,
      curve: widget.opacityAnimationCurve,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_index == null || _fractionOfThumb == null) return Container();

    return _addAnimatedOpacity(
      child: Stack(
        children: [
          RoundProgressBarTrack(
            padding: widget.padding,
            width: widget.width,
            color: widget.trackColor,
          ),
          RoundScrollBarThumb(
            padding: widget.padding,
            width: widget.width,
            fraction: _fractionOfThumb!,
            index: _index!,
            color: widget.thumbColor,
          )
        ],
      ),
    );
  }
}

class RoundProgressBarTrack extends StatelessWidget {
  final double padding;
  final double width;
  final Color? color;

  const RoundProgressBarTrack({
    required this.padding,
    required this.width,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _RoundProgressBarPainter(
        angleLength: _kProgressBarLength,
        color: color ?? Theme.of(context).highlightColor,
        startingAngle: _kProgressBarStartingPoint,
        trackPadding: padding,
        trackWidth: width,
      ),
    );
  }
}

class RoundScrollBarThumb extends StatelessWidget {
  final double padding;
  final double width;
  final Color? color;
  final double fraction;
  final double index;

  const RoundScrollBarThumb({
    required this.padding,
    required this.width,
    required this.fraction,
    required this.index,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final angleLength = _kProgressBarLength * fraction;
    return Transform.rotate(
      angle: index * angleLength,
      child: CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _RoundProgressBarPainter(
          angleLength: angleLength,
          startingAngle: _kProgressBarStartingPoint,
          color: color ?? Theme.of(context).highlightColor.withOpacity(1.0),
          trackPadding: padding,
          trackWidth: width,
        ),
      ),
    );
  }
}

class _RoundProgressBarPainter extends CustomPainter {
  final double startingAngle;
  final double angleLength;
  final Color color;
  final double trackWidth;
  final double trackPadding;

  _RoundProgressBarPainter({
    required this.angleLength,
    required this.color,
    required this.trackPadding,
    required this.trackWidth,
    this.startingAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = trackWidth.toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerOffset = Offset(
      size.width / 2,
      size.height / 2,
    );

    final innerWidth = size.width - trackPadding * 2 - trackWidth;
    final innerHeight = size.height - trackPadding * 2 - trackWidth;

    final path = Path()
      ..arcTo(
        Rect.fromCenter(
          center: centerOffset,
          width: innerWidth,
          height: innerHeight,
        ),
        startingAngle,
        angleLength,
        true,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundProgressBarPainter oldDelegate) {
    return color != oldDelegate.color ||
        startingAngle != oldDelegate.startingAngle ||
        angleLength != oldDelegate.angleLength ||
        trackWidth != oldDelegate.trackWidth ||
        trackPadding != oldDelegate.trackPadding;
  }
}
