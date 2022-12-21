import 'package:flutter/material.dart';
import 'package:rotary_scrollbar/widgets/rotary_scrollbar.dart';

class RotaryScrollWrapper extends StatelessWidget {
  /// A scrollable widget, such as [PageView] or [ListView] or [SingleChildScrollView].
  final Widget child;

  /// A scrollbar adapted to round screens that reacts to rotary events.
  final RotaryScrollbar rotaryScrollbar;

  /// Displays a [RotaryScrollbar] on top of a scrollable `child`.
  /// This can be a [PageView], [ListView], [SingleChildScrollView] or any other scroll view.
  const RotaryScrollWrapper({
    required this.rotaryScrollbar,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: rotaryScrollbar,
        ),
      ],
    );
  }
}
