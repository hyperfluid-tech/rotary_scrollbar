// ignore_for_file: no_logic_in_create_state, invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rotary_scrollbar/widgets/round_scrollbar.dart';
import 'package:vibration/vibration.dart';
import 'package:wearable_rotary/wearable_rotary.dart';

/// A scrollbar that curves around circular screens and reacts to Rotary events.
///
/// Similar to the native Wear OS scrollbar on devices with round screens.
/// It can be wrapped around a `PageView`, `ListView` or any other scrollable view.
/// And it is able to control the view's `ScrollController` or `PageController`
/// with touch input (scroll gesture) or by rotary input.
/// Includes haptic feedback for each rotary event.
///
/// See also:
/// - [RoundScrollbar], for a similar scrollbar except it doesn't react to rotary input.
class RotaryScrollbar extends StatefulWidget {
  /// Whether the device should vibrate after each page transition.
  final bool hasHapticFeedback;

  /// Duration of the animation between page transitions.
  final Duration pageTransitionDuration;

  /// Animation curve for page transitions.
  final Curve pageTransitionCurve;

  /// Duration of the animation between scrolls.
  final Duration scrollAnimationDuration;

  /// Animation curve for scroll animations.
  final Curve scrollAnimationCurve;

  /// ScrollController for the scrollbar.
  final ScrollController controller;

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

  /// Adjust scroll magnitude.
  ///
  /// A higher value means bigger jumps between rotary scrolls.
  final double scrollMagnitude;

  /// The widget that will be scrolled.
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
  State<RotaryScrollbar> createState() {
    if (controller is PageController) {
      return _RotaryScrollbarPageState();
    }

    return _RotaryScrollbarState();
  }
}

class _RotaryScrollbarState extends State<RotaryScrollbar> {
  static const _kVibrationDuration = 25;
  static const _kVibrationAmplitude = 64;

  // Prevents onEdgeVibration to be triggered more than once per second
  static const _kOnEdgeVibrationDelay = Duration(seconds: 1);

  late final StreamSubscription<RotaryEvent> _rotarySubscription;

  num _currentPos = 0;

  @override
  void initState() {
    _initRotarySubscription();
    _initControllerListeners();
    super.initState();
  }

  void _initControllerListeners() {
    widget.controller.addListener(_scrollControllerListener);
    if (widget.controller.hasClients) {
      _currentPos = widget.controller.offset;
    }
  }

  void _scrollControllerListener() {
    if (_isAnimating) return;
    _currentPos = widget.controller.offset;
  }

  void _initRotarySubscription() {
    _rotarySubscription = rotaryEvents.listen(_rotaryEventListener);
  }

  void _rotaryEventListener(RotaryEvent event) {
    if (_isAtEdge(event.direction)) {
      _scrollOnEdge(event);
      return;
    }

    _rotaryEventListenerScrollController(event);
  }

  num _getNextPosition(RotaryEvent event) =>
      _currentPos +
      widget.scrollMagnitude *
          (event.direction == RotaryDirection.clockwise ? 1 : -1);

  void _rotaryEventListenerScrollController(RotaryEvent event) {
    final nextPos = _getNextPosition(event);
    _scrollAndVibrate(nextPos);
    _currentPos = nextPos;
  }

  int _currentUpdate = 0;
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

  bool _isVibratingOnEdge = false;

  void _scrollOnEdge(RotaryEvent event) {
    if (_isVibratingOnEdge) return;

    _isVibratingOnEdge = true;
    widget.controller.notifyListeners();
    final nextPosition = _getNextPosition(event);
    _scrollAndVibrate(nextPosition);
    Future.delayed(_kOnEdgeVibrationDelay, () => _isVibratingOnEdge = false);
  }

  bool _isAtEdge(RotaryDirection direction) {
    switch (direction) {
      case RotaryDirection.clockwise:
        return widget.controller.offset ==
            widget.controller.position.maxScrollExtent;
      case RotaryDirection.counterClockwise:
        return widget.controller.offset == 0;
    }
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

class _RotaryScrollbarPageState extends _RotaryScrollbarState {
  PageController get _pageController => widget.controller as PageController;

  @override
  void _initControllerListeners() {
    _pageController.addListener(_pageControllerListener);
    _currentPos = _pageController.initialPage;
  }

  @override
  void _disposeControllerListeners() {
    _pageController.removeListener(_pageControllerListener);
  }

  void _pageControllerListener() {
    if (_isAnimating) return;
    _currentPos = _pageController.page!.toInt();
  }

  @override
  Future<void> _scrollToPosition(num pos) async {
    return _pageController.animateToPage(
      pos.toInt(),
      duration: widget.pageTransitionDuration,
      curve: widget.pageTransitionCurve,
    );
  }

  @override
  num _getNextPosition(RotaryEvent event) =>
      _currentPos + (event.direction == RotaryDirection.clockwise ? 1 : -1);

  @override
  bool _isAtEdge(RotaryDirection direction) {
    switch (direction) {
      case RotaryDirection.clockwise:
        return _currentPos ==
            (widget.controller.position.maxScrollExtent /
                widget.controller.position.viewportDimension);
      case RotaryDirection.counterClockwise:
        return _currentPos == 0;
    }
  }
}
