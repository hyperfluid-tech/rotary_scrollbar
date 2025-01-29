import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotary_scrollbar/widgets/round_scrollbar.dart';

const defaultOpacityDuration = Duration(milliseconds: 250);
const defaultAutoHideDuration = Duration(seconds: 3);
const defaultThumbColor = Colors.red;
const defaultTrackColor = Colors.blue;
const defaultWidth = 8.0;
void main() {
  Future<void> setUpWidget(
    WidgetTester tester, {
    ScrollController? controller,
    bool autoHide = true,
    Duration autoHideDuration = defaultAutoHideDuration,
    Duration opacityAnimationDuration = defaultOpacityDuration,
    Color? thumbColor = defaultThumbColor,
    Color? trackColor = defaultTrackColor,
    double width = defaultWidth,
  }) async {
    tester.view.physicalSize = Size(500, 500);
    await tester.pumpWidget(
      MaterialApp(
        home: ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.fromMap(
              {
                WidgetState.any: thumbColor,
              },
            ),
            trackColor: WidgetStateProperty.fromMap(
              {
                WidgetState.any: defaultTrackColor,
              },
            ),
          ),
          child: RoundScrollbar(
            controller: controller,
            autoHide: autoHide,
            autoHideDuration: autoHideDuration,
            opacityAnimationDuration: opacityAnimationDuration,
            width: width,
            child: ListView(
              controller: controller,
              children: List.generate(
                5,
                (i) => SizedBox.square(
                  key: ValueKey(i),
                  dimension: 500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('RoundScrollbar builds a CustomPaint', (tester) async {
    await setUpWidget(tester);

    expect(find.byType(CustomPaint), findsNWidgets(2));

    await tester.pump(Duration(seconds: 3));
  });

  testWidgets(
      'RoundScrollbar shows scrollbar on app start then hides by default',
      (tester) async {
    await setUpWidget(tester);
    final renderObject = tester.renderObject(find.descendant(
        of: find.byType(RoundScrollbar), matching: find.byType(CustomPaint)));
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
    await tester.pumpAndSettle(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(defaultAutoHideDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
  });

  testWidgets('RoundScrollbar does not hide scrollbar WHEN autoHide is false',
      (tester) async {
    await setUpWidget(tester, autoHide: false);
    final renderObject = tester.renderObject(find.descendant(
        of: find.byType(RoundScrollbar), matching: find.byType(CustomPaint)));
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
    await tester.pumpAndSettle(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(defaultAutoHideDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
  });

  testWidgets(
      'RoundScrollbar shows scrollbar on app start then hides by default with custom opacity duration',
      (tester) async {
    const customOpacityDuration = Duration(milliseconds: 900);
    await setUpWidget(tester, opacityAnimationDuration: customOpacityDuration);
    final renderObject = tester.renderObject(find.descendant(
        of: find.byType(RoundScrollbar), matching: find.byType(CustomPaint)));
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
    await tester.pumpAndSettle(customOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(defaultAutoHideDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(customOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
  });

  testWidgets(
      'RoundScrollbar shows scrollbar on app start then hides by default with custom autohide duration',
      (tester) async {
    const customAutoHideDuration = Duration(milliseconds: 1394);
    await setUpWidget(tester, autoHideDuration: customAutoHideDuration);
    final renderObject = tester.renderObject(find.descendant(
        of: find.byType(RoundScrollbar), matching: find.byType(CustomPaint)));
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
    await tester.pumpAndSettle(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(customAutoHideDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1));
    await tester.pump(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 0));
  });

  testWidgets('RoundScrollbar paints scrollbar with custom width',
      (tester) async {
    const customWidth = 20.0;
    await setUpWidget(
      tester,
      autoHide: false,
      width: customWidth,
    );
    final renderObject = tester.renderObject(find.descendant(
        of: find.byType(RoundScrollbar), matching: find.byType(CustomPaint)));
    expect(renderObject, paintsTrackAndThumb(opacity: 0, width: customWidth));
    await tester.pumpAndSettle(defaultOpacityDuration);
    expect(renderObject, paintsTrackAndThumb(opacity: 1, width: customWidth));
    await tester.pump(defaultAutoHideDuration);
  });
}

PaintPattern paintsTrackAndThumb({
  required double opacity,
  Color? thumbColor = defaultThumbColor,
  Color? trackColor = defaultTrackColor,
  double width = defaultWidth,
}) =>
    paints
      ..path(
        color: trackColor?.withValues(
          alpha: opacity,
        ),
        strokeWidth: width,
      )
      ..path(
        color: thumbColor?.withValues(
          alpha: opacity,
        ),
        strokeWidth: width,
      );
