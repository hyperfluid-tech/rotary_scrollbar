import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rotary_scrollbar/widgets/round_scrollbar.dart';
import 'package:vibration/vibration.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

/// A specialized scrollbar designed for Wear OS devices with rotary input.
///
/// This widget enhances the [RoundScrollbar] by adding support for rotary
/// events, enabling users to scroll through content using a rotating bezel or
/// crown. It also provides haptic feedback for each scroll tick, enhancing the
/// user experience. It can be used with any scrollable widget like `PageView`,
/// `ListView`, etc.
///
/// See also:
///
///  * [RoundScrollbar], the base scrollbar widget that this class extends. It
/// provides the visual representation of the scrollbar but lacks rotary
/// input handling.
class RotaryScrollbar<T extends ScrollController> extends StatefulWidget {
  /// Determines whether haptic feedback (vibration) is generated for each
  /// scroll tick.
  ///
  /// Defaults to `true`.
  final bool hasHapticFeedback;

  /// The duration of the animation when transitioning between pages in a
  /// [PageView].
  ///
  /// This [Duration] is used by the internal [PageController] to animate page
  /// changes triggered by rotary input.
  ///
  /// Defaults to 250 milliseconds.
  final Duration pageTransitionDuration;

  /// The animation curve used for page transitions in a [PageView].
  ///
  /// This [Curve] is applied to the page animation controlled by the internal
  /// [PageController].
  ///
  /// Defaults to [Curves.easeInOutCirc].
  final Curve pageTransitionCurve;

  /// The duration of the scroll animation for scrollable widgets other than
  /// [PageView].
  ///
  /// Defaults to 100 milliseconds.
  final Duration scrollAnimationDuration;

  /// The animation curve to use for scroll animations triggered by rotary input.
  ///
  /// Defaults to [Curves.linear].
  final Curve scrollAnimationCurve;

  /// The [ScrollController] or [PageController] for the scrollable widget that this scrollbar
  /// controls.
  final T controller;

  /// The padding around the scrollbar track.
  ///
  /// This value defines the space between the scrollbar and the edges of the
  /// screen.
  ///
  /// Defaults to 8 logical pixels.
  final double padding;

  /// The width of the scrollbar track and thumb.
  ///
  /// Defaults to 8 logical pixels.
  final double width;

  /// Whether the scrollbar should automatically hide after a period of
  /// inactivity.
  ///
  /// Defaults to `true`.
  final bool autoHide;

  /// The animation curve used to control the showing and hiding animation of
  /// the scrollbar.
  ///
  /// Defaults to [Curves.easeInOut].
  final Curve opacityAnimationCurve;

  /// The duration of the animation for showing and hiding the scrollbar.
  ///
  /// Defaults to 250 milliseconds.
  final Duration opacityAnimationDuration;

  /// The amount of time the scrollbar remains visible after a scroll event
  /// before fading out.
  ///
  /// Defaults to 3 seconds.
  final Duration autoHideDuration;

  /// Adjusts the scroll magnitude for rotary input.
  ///
  /// A higher value results in larger scroll jumps for each rotary tick.
  ///
  /// Defaults to 50.
  final double scrollMagnitude;

  /// The widget that will be wrapped with the scrollbar.
  ///
  /// Typically, this is a scrollable widget like `ListView`, `PageView`, or
  /// `CustomScrollView`.
  final Widget child;

  /// Creates a [RotaryScrollbar].
  const RotaryScrollbar({
    super.key,
    required this.controller,
    required this.child,
    this.padding = 8,
    this.width = 8,
    this.autoHide = true,
    this.opacityAnimationCurve = Curves.easeInOut,
    this.opacityAnimationDuration = const Duration(milliseconds: 250),
    this.autoHideDuration = const Duration(seconds: 3),
    this.hasHapticFeedback = true,
    this.pageTransitionDuration = const Duration(milliseconds: 250),
    this.pageTransitionCurve = Curves.easeInOutCirc,
    this.scrollMagnitude = 50,
    this.scrollAnimationDuration = const Duration(milliseconds: 100),
    this.scrollAnimationCurve = Curves.linear,
  });

  @override
  State<RotaryScrollbar> createState() => _RotaryScrollbarState();
}

class _RotaryScrollbarState<T extends ScrollController>
    extends State<RotaryScrollbar<T>> {
  static const _kVibrationDuration = 25;

  static const _kVibrationAmplitude = 64;

  static const _kOnEdgeVibrationDelay = Duration(seconds: 1);

  late final StreamSubscription<RotaryEvent> _rotarySubscription;

  num _currentPos = 0;

  void _initRotarySubscription() {
    _rotarySubscription = rotaryEvents.listen(_rotaryEventListener);
  }

  void _initControllerListeners() {
    widget.controller.addListener(_scrollControllerListener);
    if (!widget.controller.hasClients) {
      return;
    }

    _currentPos = switch (widget.controller) {
      final PageController pageController => pageController.initialPage,
      _ => widget.controller.offset,
    };
  }

  void _scrollControllerListener() {
    if (_isAnimating) return;

    _currentPos = switch (widget.controller) {
      final PageController pageController => pageController.page?.toInt() ?? 0,
      _ => widget.controller.offset,
    };
  }

  void _rotaryEventListener(RotaryEvent event) {
    if (_isAtEdge(event.direction)) {
      _scrollOnEdge(event);
      return;
    }

    _rotaryEventListenerScrollController(event);
  }

  num _getNextPosition(RotaryEvent event) {
    final direction = switch (event.direction) {
      RotaryDirection.clockwise => 1,
      RotaryDirection.counterClockwise => -1,
    };

    final magnitude = switch (widget.controller) {
      PageController() => 1,
      _ => widget.scrollMagnitude,
    };

    return _currentPos + (magnitude * direction);
  }

  void _rotaryEventListenerScrollController(RotaryEvent event) {
    final nextPos = _getNextPosition(event);
    _scrollAndVibrate(nextPos);
    _currentPos = nextPos;
  }

  /// Tracks the current animation update to prevent overlapping animations.
  int _currentUpdate = 0;

  /// Indicates whether an animation is currently in progress.
  bool _isAnimating = false;

  void _updateIsAnimating(int thisUpdate) {
    if (thisUpdate != _currentUpdate) return;
    _isAnimating = false;
  }

  void _scrollAndVibrate(num pos) {
    _isAnimating = true;
    _currentUpdate++;
    final thisUpdate = _currentUpdate;
    _scrollToPosition(pos).then((_) => _updateIsAnimating(thisUpdate));
    _triggerVibration();
  }

  Future<void> _scrollToPosition(num pos) async {
    if (widget.controller case final PageController pageController) {
      return pageController.animateToPage(
        pos.toInt(),
        duration: widget.pageTransitionDuration,
        curve: widget.pageTransitionCurve,
      );
    }
    return widget.controller.animateTo(
      pos.toDouble(),
      duration: widget.scrollAnimationDuration,
      curve: widget.scrollAnimationCurve,
    );
  }

  void _triggerVibration() {
    if (!widget.hasHapticFeedback) return;
    Vibration.vibrate(
      duration: _kVibrationDuration,
      amplitude: _kVibrationAmplitude,
    );
  }

  Timer? _vibratingOnEdgeTimer;
  void _scrollOnEdge(RotaryEvent event) {
    if (_vibratingOnEdgeTimer?.isActive ?? false) return;

    _vibratingOnEdgeTimer = Timer(_kOnEdgeVibrationDelay, () {});
    final nextPosition = _getNextPosition(event);
    _scrollAndVibrate(nextPosition);
  }

  bool _isAtEdge(RotaryDirection direction) {
    switch (direction) {
      case RotaryDirection.clockwise:
        return widget.controller.position.extentAfter == 0;
      case RotaryDirection.counterClockwise:
        return widget.controller.position.extentBefore == 0;
    }
  }

  @override
  void initState() {
    _initRotarySubscription();
    _initControllerListeners();
    super.initState();
  }

  @override
  void dispose() {
    _disposeRotarySubscription();
    _disposeControllerListeners();
    super.dispose();
  }

  void _disposeRotarySubscription() {
    _rotarySubscription.cancel();
  }

  void _disposeControllerListeners() {
    widget.controller.removeListener(_scrollControllerListener);
  }

  @override
  Widget build(BuildContext context) {
    return RoundScrollbar(
      controller: widget.controller,
      width: widget.width,
      padding: widget.padding,
      autoHide: widget.autoHide,
      autoHideDuration: widget.autoHideDuration,
      opacityAnimationCurve: widget.opacityAnimationCurve,
      opacityAnimationDuration: widget.opacityAnimationDuration,
      child: widget.child,
    );
  }
}
