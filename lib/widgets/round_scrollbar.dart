import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

// Defines the starting point of the progress bar arc on the screen.
// This is equivalent to the 2 o'clock position on an analog clock.
const _kProgressBarStartingPoint = math.pi * (-1 / 2 + 1 / 3);

// Defines the ending point of the progress bar arc on the screen.
// This is equivalent to the 4 o'clock position on an analog clock.
const _kProgressBarLength = math.pi / 3;

/// A curved scrollbar designed for circular Wear OS screens.
///
/// This widget provides a visually appealing and intuitive scrollbar that
/// follows the curvature of round displays. It's designed to work seamlessly
/// with scrollable views like `PageView`, `ListView`, and others. The scrollbar
/// can be controlled through touch gestures on the scrollable content.
///
/// See also:
///
///  * [RotaryScrollbar], a similar scrollbar that also responds to rotary
/// input events from devices with rotating bezels or crowns.
class RoundScrollbar extends StatefulWidget {
  /// The [ScrollController] associated with the scrollable widget this
  /// scrollbar is controlling.
  ///
  /// If not provided, it defaults to the [PrimaryScrollController] in the
  /// current [BuildContext]. This fallback is useful in many typical scenarios
  /// where a single, primary scrollable area exists within a given context.
  final ScrollController? controller;

  /// The padding around the scrollbar track.
  ///
  /// This value defines the space between the scrollbar and the edges of the
  /// screen.
  ///
  /// Defaults to 8 logical pixels.
  final double padding;

  /// The width of the scrollbar track and thumb.
  ///
  /// This determines the thickness of the scrollbar.
  ///
  /// Defaults to 8 logical pixels.
  final double width;

  /// Determines whether the scrollbar should automatically hide after a period
  /// of inactivity.
  ///
  /// Defaults to `true`.
  final bool autoHide;

  /// The animation curve used to control the showing and hiding animation of
  /// the scrollbar.
  ///
  /// This [Curve] is applied when the scrollbar's opacity changes due to
  /// [autoHide].
  ///
  /// Defaults to [Curves.easeInOut].
  final Curve opacityAnimationCurve;

  /// The duration of the animation for showing and hiding the scrollbar.
  ///
  /// This [Duration] is used for the opacity animation triggered by [autoHide].
  ///
  /// Defaults to 250 milliseconds.
  final Duration opacityAnimationDuration;

  /// The amount of time the scrollbar remains visible after a scroll event
  /// before fading out.
  ///
  /// This delay is applicable only when [autoHide] is `true`.
  ///
  /// Defaults to 3 seconds.
  final Duration autoHideDuration;

  /// Overrides the default color of the scrollbar track.
  ///
  /// If not specified, the track color is derived from the
  /// `scrollbarTheme.trackColor` in the application's theme. If that is also
  /// null, it falls back to the theme's `highlightColor`.
  final Color? trackColor;

  /// Overrides the default color of the scrollbar thumb.
  ///
  /// If not specified, the thumb color is derived from the
  /// `scrollbarTheme.thumbColor` in the application's theme. If that is also
  /// null, it falls back to the theme's `highlightColor` with an alpha of 255.
  final Color? thumbColor;

  /// The widget that will be wrapped with the scrollbar.
  ///
  /// Typically, this is a scrollable widget like `ListView`, `PageView`, or
  /// `CustomScrollView`.
  final Widget child;

  /// Creates a [RoundScrollbar].
  ///
  /// The [child] parameter is required and represents the scrollable widget
  /// that the scrollbar will control.
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
  ScrollController? _currentController;

  late final _RoundProgressBarPainter _painter;

  late final AnimationController _opacityController;

  late final Animation<double> _opacityAnimation;
  Timer? _fadeOutTimer;

  void _onScroll() {
    final controller = _currentController;
    if (controller == null ||
        !controller.position.hasViewportDimension ||
        controller.position.extentInside == controller.position.extentTotal) {
      return;
    }
    _updateScrollbarPainter(controller);
    if (!_opacityController.isAnimating) _opacityController.forward();
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
      if (mounted) {
        _opacityController.reverse();
      }
      _fadeOutTimer = null;
    });
  }

  @override
  void didUpdateWidget(covariant RoundScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _updateController();
    }
    if (oldWidget.opacityAnimationDuration != widget.opacityAnimationDuration) {
      _opacityController.duration = widget.opacityAnimationDuration;
    }
    if (oldWidget.thumbColor != widget.thumbColor ||
        oldWidget.trackColor != widget.trackColor) {
      _updatePainter();
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
    _updatePainter();
    _updateController();
  }

  void _updatePainter() {
    _painter
      ..track.color = widget.trackColor ??
          ScrollbarTheme.of(context).trackColor?.resolve(<WidgetState>{}) ??
          Theme.of(context).highlightColor
      ..thumb.color = widget.thumbColor ??
          ScrollbarTheme.of(context).thumbColor?.resolve(<WidgetState>{}) ??
          Theme.of(context).highlightColor.withAlpha(255);
  }

  void _updateController() {
    _currentController?.removeListener(_onScroll);
    _currentController =
        widget.controller ?? PrimaryScrollController.of(context);
    _currentController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _currentController?.removeListener(_onScroll);
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onScrollMetricsChange,
      child: CustomPaint(
        foregroundPainter: _painter,
        child: RepaintBoundary(
          child: PrimaryScrollController(
            controller: _currentController!,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Represents a segment of the circular progress bar, either the track or the
/// thumb.
class _RoundProgressBarPart {
  /// The starting angle of the segment in radians.
  double startAngle;

  /// The length of the segment in radians.
  double length;

  /// The color of the segment.
  Color? color;

  /// Creates a [_RoundProgressBarPart].
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

/// Paints the circular progress bar on a [Canvas].
class _RoundProgressBarPainter extends ChangeNotifier implements CustomPainter {
  /// The track part of the progress bar.
  final _RoundProgressBarPart track;

  /// The thumb part of the progress bar.
  final _RoundProgressBarPart thumb;

  /// The animation that controls the opacity of the progress bar.
  final Animation<double> opacityAnimation;

  /// The width of the track.
  final double trackWidth;

  /// The padding around the track.
  final double trackPadding;

  /// Creates a [_RoundProgressBarPainter].
  _RoundProgressBarPainter({
    required Color? thumbColor,
    required this.track,
    required this.trackPadding,
    required this.trackWidth,
    required this.opacityAnimation,
  }) : thumb = _RoundProgressBarPart(
          color: thumbColor,
          startAngle: track.startAngle,
          length: track.length,
        ) {
    opacityAnimation.addListener(notifyListeners);
  }

  /// Updates the thumb's position and size based on the scroll progress.
  ///
  /// [index] represents the current scroll offset as a fraction of the viewport
  /// size.
  ///
  /// [fraction] represents the size of the thumb relative to the track length.
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

  /// Paints a specific part of the progress bar (track or thumb).
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

    // Calculates the inner dimensions of the scrollbar track, excluding padding and width.
    final innerWidth = size.width - trackPadding * 2 - trackWidth;
    final innerHeight = size.height - trackPadding * 2 - trackWidth;

    // Creates a Rect that defines the bounds of the track, centered within the widget.
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
