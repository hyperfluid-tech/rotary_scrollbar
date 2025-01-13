import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

// Starts at the 2 o'clock marker on an analog clock.
const _kProgressBarStartingPoint = math.pi * (-1 / 2 + 1 / 3);

// Finishes at the 4 o'clock marker on an analog clock.
const _kProgressBarLength = math.pi / 3;

/// A scrollbar that curves around circular screens and reacts to Rotary events.
///
/// Similar to the native Wear OS scrollbar on devices with round screens.
/// It can be wrapped around a `PageView`, `ListView` or any other scrollable view.
/// And it is able to control the view's `ScrollController` or `PageController`
/// with touch input (scroll gesture).
///
/// See also:
/// - [RotaryScrollbar], for a similar scrollbar that reacts to rotary input.
class RoundScrollbar extends StatefulWidget {
  /// ScrollController for the scrollbar.
  ///
  /// If null, it will use the [PrimaryScrollController] from the context.
  final ScrollController? controller;

  /// Padding between the edges of the screen and scrollbar track.
  final double padding;

  /// Width of the scrollbar track and thumb.
  final double width;

  /// Whether the scrollbar should hide automatically if inactive.
  final bool autoHide;

  /// Animation curve for the showing/hiding animation.
  final Curve opacityAnimationCurve;

  /// Animation duration for the showing/hiding animation.
  final Duration opacityAnimationDuration;

  /// How long the scrollbar is displayed after a scroll event.
  final Duration autoHideDuration;

  /// Overrides the color of the scrollbar track.
  ///
  /// If null, it will use the `scrollbarTheme.trackColor` from the context.
  final Color? trackColor;

  /// Overrides the color of the scrollbar thumb.
  ///
  /// If null, it will use the `scrollbarTheme.thumbColor` from the context.
  final Color? thumbColor;

  /// The widget that will be scrolled.
  final Widget child;

  /// Creates a [RoundScrollbar].
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
      Theme.of(context).highlightColor.withAlpha(255);

  void _onScroll() {
    final controller = _currentController;
    if (controller == null || !controller.position.hasViewportDimension) return;
    _updateScrollbarPainter(controller);
    _opacityController.forward();
    _maybeHideAfterDelay();
  }

  double? _viewPortDimensions;

  bool _onScrollMetricsChange(ScrollMetricsNotification notification) {
    if (!notification.metrics.hasViewportDimension ||
        !notification.metrics.hasContentDimensions ||
        _viewPortDimensions == notification.metrics.viewportDimension) {
      return false;
    }
    _onScroll();
    _viewPortDimensions = notification.metrics.viewportDimension;

    return false;
  }

  void _updateScrollbarPainter(ScrollController controller) {
    final thumbFraction = 1 /
        ((controller.position.maxScrollExtent /
                controller.position.viewportDimension) +
            1);
    final index = (controller.offset / controller.position.viewportDimension);

    _painter.updateThumb(index, thumbFraction);
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
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onScrollMetricsChange,
      child: CustomPaint(
        foregroundPainter: _painter,
        child: RepaintBoundary(
          child: widget.child,
        ),
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
      ..color = part.color?.withValues(alpha: part.color!.a * opacity) ??
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
