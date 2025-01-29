import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rotary_scrollbar/widgets/round_scrollbar.dart';

const defaultOpacityDuration = Duration(milliseconds: 250);
const defaultAutoHideDuration = Duration(seconds: 3);
const defaultThumbColor = Colors.red;
const defaultTrackColor = Colors.blue;
const defaultWidth = 8.0;
const defaultOpacityAnimationCurve = Curves.easeInOut;

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
    Curve opacityAnimationCurve = defaultOpacityAnimationCurve,
  }) async {
    tester.view.physicalSize = const Size(500, 500);
    await tester.pumpWidget(
      MaterialApp(
        home: ScrollbarTheme(
          data: ScrollbarThemeData(
            thumbColor: WidgetStateProperty.fromMap(
              {WidgetState.any: thumbColor},
            ),
            trackColor: WidgetStateProperty.fromMap(
              {WidgetState.any: trackColor},
            ),
          ),
          child: RoundScrollbar(
            controller: controller,
            autoHide: autoHide,
            autoHideDuration: autoHideDuration,
            opacityAnimationDuration: opacityAnimationDuration,
            opacityAnimationCurve: opacityAnimationCurve,
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
    await tester.pump();
  }

  group('Basic rendering', () {
    testWidgets(
      'GIVEN a RoundScrollbar '
      'WHEN first built '
      'THEN renders two CustomPaint elements',
      (tester) async {
        // Arrange & Act
        await setUpWidget(tester);

        // Assert
        expect(find.byType(CustomPaint), findsNWidgets(2));

        await tester.pumpAndSettle(defaultAutoHideDuration);
      },
    );
  });

  group('Auto-hide functionality', () {
    testWidgets(
      'GIVEN autoHide is true '
      'WHEN first rendered '
      'THEN scrollbar is initially hidden',
      (tester) async {
        // Arrange & Act
        await setUpWidget(tester);
        final renderObject = getRenderObject(tester);

        // Assert
        expect(renderObject, paintsTrackAndThumb(opacity: 0));

        await tester.pump(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN autoHide is true '
      'WHEN animation completes '
      'THEN scrollbar becomes fully visible',
      (tester) async {
        // Arrange
        await setUpWidget(tester);
        final renderObject = getRenderObject(tester);

        // Act
        await tester.pumpAndSettle(defaultOpacityDuration);

        // Assert
        expect(renderObject, paintsTrackAndThumb(opacity: 1));

        await tester.pump(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN autoHide is true '
      'WHEN autoHide duration elapses '
      'THEN scrollbar fades out',
      (tester) async {
        // Arrange
        await setUpWidget(tester);
        final renderObject = getRenderObject(tester);
        await tester.pumpAndSettle(defaultOpacityDuration);

        // Act
        await tester.pump(defaultAutoHideDuration);
        await tester.pump(defaultOpacityDuration);

        // Assert
        expect(renderObject, paintsTrackAndThumb(opacity: 0));
      },
    );

    testWidgets(
      'GIVEN autoHide is false '
      'WHEN any duration elapses '
      'THEN scrollbar remains visible',
      (tester) async {
        // Arrange
        await setUpWidget(tester, autoHide: false);
        final renderObject = getRenderObject(tester);
        await tester.pumpAndSettle(defaultOpacityDuration);

        // Act
        await tester.pump(defaultAutoHideDuration * 2);

        // Assert
        expect(renderObject, paintsTrackAndThumb(opacity: 1));
      },
    );
  });

  group('Animation control', () {
    testWidgets(
      'GIVEN custom opacity duration '
      'WHEN fading in '
      'THEN uses specified duration',
      (tester) async {
        // Arrange
        const customOpacityDuration = Duration(milliseconds: 900);
        await setUpWidget(
          tester,
          opacityAnimationDuration: customOpacityDuration,
        );
        final renderObject = getRenderObject(tester);

        // Act & Assert
        await tester.pump(customOpacityDuration ~/ 2);
        expect(
          renderObject,
          paintsTrackAndThumb(
              opacity: defaultOpacityAnimationCurve.transform(0.5)),
        );

        await tester.pumpAndSettle();
        expect(
          renderObject,
          paintsTrackAndThumb(opacity: 1),
        );

        await tester.pumpAndSettle(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN custom opacity curve '
      'WHEN animating '
      'THEN applies specified curve',
      (tester) async {
        // Arrange
        const customCurve = Curves.easeOut;
        await setUpWidget(tester, opacityAnimationCurve: customCurve);
        final renderObject = getRenderObject(tester);

        // Act
        await tester.pump(defaultOpacityDuration ~/ 2);

        // Assert
        expect(
          renderObject,
          paintsTrackAndThumb(opacity: customCurve.transform(0.5)),
        );

        await tester.pumpAndSettle();
        expect(renderObject, paintsTrackAndThumb(opacity: 1));

        await tester.pumpAndSettle(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN custom autoHide duration '
      'WHEN maintaining visibility '
      'THEN uses specified duration before fading',
      (tester) async {
        // Arrange
        const customAutoHideDuration = Duration(milliseconds: 1394);
        await setUpWidget(tester, autoHideDuration: customAutoHideDuration);
        final renderObject = getRenderObject(tester);
        await tester.pumpAndSettle(defaultOpacityDuration);

        // Act & Assert
        await tester.pump(customAutoHideDuration ~/ 2);
        expect(renderObject, paintsTrackAndThumb(opacity: 1));

        await tester.pump(customAutoHideDuration);
        await tester.pump(defaultOpacityDuration);
        expect(renderObject, paintsTrackAndThumb(opacity: 0));
      },
    );
  });

  group('Visual appearance', () {
    testWidgets(
      'GIVEN a custom width '
      'WHEN painting scrollbar '
      'THEN uses specified width for track and thumb',
      (tester) async {
        // Arrange
        const customWidth = 20.0;
        await setUpWidget(tester, width: customWidth);
        final renderObject = getRenderObject(tester);

        // Act
        await tester.pumpAndSettle();

        // Assert
        expect(
          renderObject,
          paintsTrackAndThumb(opacity: 1, width: customWidth),
        );

        await tester.pump(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN custom colors '
      'WHEN painting scrollbar '
      'THEN uses specified colors for track and thumb',
      (tester) async {
        // Arrange
        const customThumbColor = Colors.green;
        const customTrackColor = Colors.yellow;
        await setUpWidget(
          tester,
          thumbColor: customThumbColor,
          trackColor: customTrackColor,
        );
        final renderObject = getRenderObject(tester);

        // Act
        await tester.pumpAndSettle(defaultOpacityDuration);

        // Assert
        expect(
          renderObject,
          paintsTrackAndThumb(
            opacity: 1,
            thumbColor: customThumbColor,
            trackColor: customTrackColor,
          ),
        );

        await tester.pump(defaultAutoHideDuration);
      },
    );
  });
}

RenderObject getRenderObject(WidgetTester tester) => tester.renderObject(
      find.descendant(
        of: find.byType(RoundScrollbar),
        matching: find.byType(CustomPaint),
      ),
    );

PaintPattern paintsTrackAndThumb({
  required double opacity,
  Color? thumbColor = defaultThumbColor,
  Color? trackColor = defaultTrackColor,
  double width = defaultWidth,
}) =>
    paints
      ..path(
        color: trackColor?.withValues(alpha: opacity),
        strokeWidth: width,
      )
      ..path(
        color: thumbColor?.withValues(alpha: opacity),
        strokeWidth: width,
      );
