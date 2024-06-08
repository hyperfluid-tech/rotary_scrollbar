import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

// starts at the 2pm marker on an analog watch
const _kProgressBarStartingPoint = math.pi * (-1 / 2 + 1 / 3);
// finishes at the 4pm marker on an analog watch
const _kProgressBarLength = math.pi / 3;

class RoundScrollbar extends StatefulWidget {
  /// ScrollController for the scrollbar.
  final ScrollController? controller;

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

  final Widget child;

  /// A scrollbar which curves around circular screens.
  /// Similar to native wearOS scrollbar in devices with round screens.
  const RoundScrollbar({
    required this.child,
    this.controller,
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
  State<StatefulWidget> createState() => _RoundScrollbarState();
}

class _RoundScrollbarState extends State<RoundScrollbar>
    with SingleTickerProviderStateMixin {
  ScrollController? get _currentController =>
      widget.controller ?? PrimaryScrollController.of(context);

  late final _RoundProgressBarPainter _painter;

  late final AnimationController _opacityController;
  late final Animation<double> _opacityAnimation;
  Timer? _fadeOutTimer;

  Color? get _trackColor =>
      widget.trackColor ??
      Theme.of(context).scrollbarTheme.trackColor?.resolve(<WidgetState>{}) ??
      Theme.of(context).highlightColor;
  Color? get _thumbColor =>
      widget.thumbColor ??
      Theme.of(context).scrollbarTheme.thumbColor?.resolve(<WidgetState>{}) ??
      Theme.of(context).highlightColor.withOpacity(1.0);

  void _onScroll() {
    final controller = _currentController;
    if (controller == null ||
        !controller.hasClients ||
        !controller.position.hasContentDimensions) return;
    _updateScrollbarPainter(controller);
    _opacityController.forward();
    _maybeHideAfterDelay();
  }

  void _updateScrollbarPainter(ScrollController controller) {
    final fractionOfThumb = 1 /
        ((controller.position.maxScrollExtent /
                controller.position.viewportDimension) +
            1);

    final index = (controller.offset / controller.position.viewportDimension);

    _painter.updateThumb(index, fractionOfThumb);
  }

  void _maybeHideAfterDelay() {
    _fadeOutTimer?.cancel();
    if (!widget.autoHide) return;
    _fadeOutTimer = Timer(widget.autoHideDuration, () {
      _opacityController.reverse();
      _fadeOutTimer = null;
    });
  }

  @override
  void didUpdateWidget(covariant RoundScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      widget.controller?.addListener(_onScroll);
    }
    if (oldWidget.opacityAnimationDuration != widget.opacityAnimationDuration) {
      _opacityController.duration = widget.opacityAnimationDuration;
    }
    if (oldWidget.thumbColor != widget.thumbColor) {
      _painter.thumb.color = _thumbColor;
    }
    if (oldWidget.trackColor != widget.trackColor) {
      _painter.track.color = _trackColor;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentController?.addListener(_onScroll);
    _opacityController = AnimationController(
      value: 0,
      vsync: this,
      duration: widget.opacityAnimationDuration,
    );
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _opacityController,
        curve: widget.opacityAnimationCurve,
      ),
    );
    _painter = _RoundProgressBarPainter(
      opacityAnimation: _opacityAnimation,
      track: _RoundProgressBarPart(
        length: _kProgressBarLength,
        startAngle: _kProgressBarStartingPoint,
        color: widget.trackColor,
      ),
      thumbColor: widget.thumbColor,
      trackPadding: widget.padding,
      trackWidth: widget.width,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _painter
      ..track.color = _trackColor
      ..thumb.color = _thumbColor;
  }

  @override
  void dispose() {
    _currentController?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _painter,
      child: RepaintBoundary(
        child: widget.child,
      ),
    );
  }
}

class _RoundProgressBarPart {
  double startAngle;
  double length;
  Color? color;

  _RoundProgressBarPart({
    required this.startAngle,
    required this.length,
    required this.color,
  });

  bool shouldRepaint(covariant _RoundProgressBarPart oldProps) {
    return startAngle != oldProps.startAngle ||
        length != oldProps.length ||
        color != oldProps.color;
  }
}

class _RoundProgressBarPainter extends ChangeNotifier implements CustomPainter {
  final _RoundProgressBarPart track;
  late final _RoundProgressBarPart thumb;
  final Animation<double> opacityAnimation;

  final double trackWidth;
  final double trackPadding;

  _RoundProgressBarPainter({
    required Color? thumbColor,
    required this.track,
    required this.trackPadding,
    required this.trackWidth,
    required this.opacityAnimation,
  }) {
    thumb = _RoundProgressBarPart(
      color: thumbColor,
      startAngle: track.startAngle,
      length: track.length,
    );
    opacityAnimation.addListener(notifyListeners);
  }

  void updateThumb(double index, double fraction) {
    thumb
      ..length = track.length * fraction
      ..startAngle = thumb.length * index + track.startAngle;
    notifyListeners();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintPart(
      part: track,
      canvas: canvas,
      size: size,
      opacity: opacityAnimation.value,
    );
    _paintPart(
      part: thumb,
      canvas: canvas,
      size: size,
      opacity: opacityAnimation.value,
    );
  }

  void _paintPart({
    required _RoundProgressBarPart part,
    required Canvas canvas,
    required Size size,
    required double opacity,
  }) {
    final paint = Paint()
      ..color = part.color?.withOpacity(part.color!.opacity * opacity) ??
          const Color(0x00000000)
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
        part.startAngle,
        part.length,
        true,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoundProgressBarPainter oldDelegate) {
    return thumb.shouldRepaint(oldDelegate.thumb) ||
        track.shouldRepaint(oldDelegate.track);
  }

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) {
    return false;
  }

  @override
  bool? hitTest(Offset position) {
    return false;
  }

  @override
  void dispose() {
    opacityAnimation.removeListener(notifyListeners);
    super.dispose();
  }
}
