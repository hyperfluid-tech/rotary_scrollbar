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
    int itemCount = 5,
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
              children: List.generate(
                itemCount,
                (i) => SizedBox.square(
                  key: ValueKey(i),
                  dimension: 150,
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
      'GIVEN no scroll interaction '
      'WHEN first built '
      'THEN renders scrollbar with initial hidden state',
      (tester) async {
        // Arrange & Act
        await setUpWidget(tester);
        final renderObject = getRenderObject(tester);

        // Assert
        expect(getCustomPaintFinder(), findsWidgets);
        expect(renderObject, paintsTrackAndThumb(opacity: 0));

        await tester.pump(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN controller is provided '
      'WHEN first built '
      'THEN attaches to controller',
      (tester) async {
        // Arrange
        final controller = ScrollController();

        // Act
        await setUpWidget(tester, controller: controller);

        // Assert
        expect(controller.hasClients, isTrue);

        await tester.pump(defaultAutoHideDuration);
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
      'GIVEN autoHide is true '
      'BUT no content is not scrollable '
      'WHEN built '
      'THEN keeps scrollbar hidden (no scroll needed)',
      (tester) async {
        // Arrange & Act
        await setUpWidget(tester, itemCount: 1);
        final renderObject = getRenderObject(tester);
        await tester.pump(defaultOpacityDuration);

        // Assert
        expect(renderObject, paintsTrackAndThumb(opacity: 0));
        await tester.pump(defaultAutoHideDuration);
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
    group('Fade in animation', () {
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
        'WHEN animating fade in '
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
    });

    group('Fade-out animation', () {
      testWidgets(
        'GIVEN visible scrollbar '
        'WHEN autoHide duration elapses '
        'THEN fades out with default curve and duration',
        (tester) async {
          // Arrange
          await setUpWidget(tester);
          final renderObject = getRenderObject(tester);
          await tester.pumpAndSettle(defaultOpacityDuration); // Fade in

          // Act
          await tester.pump(defaultAutoHideDuration);
          await tester.pump(defaultOpacityDuration ~/ 2);

          // Assert intermediate state
          expect(
            renderObject,
            paintsTrackAndThumb(
              opacity: defaultOpacityAnimationCurve.transform(0.5),
            ),
          );

          // Act - complete animation
          await tester.pumpAndSettle();

          // Assert final state
          expect(renderObject, paintsTrackAndThumb(opacity: 0));
        },
      );

      testWidgets(
        'GIVEN fading out '
        'WHEN user scrolls '
        'THEN initiates new fade-in animation',
        (tester) async {
          // Arrange
          await setUpWidget(tester);
          final renderObject = getRenderObject(tester);
          await tester.pumpAndSettle(defaultAutoHideDuration);
          await tester.pumpAndSettle(defaultOpacityDuration ~/ 2);

          // Initial scroll to show scrollbar
          await simulateScrollGesture(tester);
          await tester.pumpAndSettle(defaultOpacityDuration ~/ 2);

          // Assert
          expect(renderObject, paintsTrackAndThumb(opacity: 1));

          await tester.pump(defaultAutoHideDuration);
        },
      );

      testWidgets(
        'GIVEN fading out '
        'WHEN scroll controller value changes '
        'THEN initiates new fade-in animation',
        (tester) async {
          // Arrange
          final controller = ScrollController();
          await setUpWidget(tester, controller: controller);
          final renderObject = getRenderObject(tester);
          await tester.pumpAndSettle(defaultAutoHideDuration);
          await tester.pumpAndSettle(defaultOpacityDuration ~/ 2);

          // Initial scroll to show scrollbar
          animateScrollController(controller, Duration(milliseconds: 200));
          await tester.pumpAndSettle(defaultOpacityDuration ~/ 2);

          // Assert
          expect(renderObject, paintsTrackAndThumb(opacity: 1));

          await tester.pump(defaultAutoHideDuration);
        },
      );

      testWidgets(
        'GIVEN custom fade-out duration '
        'WHEN autoHide triggers '
        'THEN uses specified duration',
        (tester) async {
          // Arrange
          const customDuration = Duration(milliseconds: 500);
          await setUpWidget(tester, opacityAnimationDuration: customDuration);
          final renderObject = getRenderObject(tester);
          await tester.pumpAndSettle(defaultOpacityDuration); // Fade in

          // Act
          await tester.pump(defaultAutoHideDuration);
          await tester.pump(customDuration ~/ 2);

          // Assert
          expect(
            renderObject,
            paintsTrackAndThumb(
              opacity: defaultOpacityAnimationCurve.transform(0.5),
            ),
          );
        },
      );

      testWidgets(
        'GIVEN custom fade-out curve '
        'WHEN autoHide triggers '
        'THEN applies specified curve',
        (tester) async {
          // Arrange
          const customCurve = Curves.easeInCirc;
          await setUpWidget(tester, opacityAnimationCurve: customCurve);
          final renderObject = getRenderObject(tester);
          await tester.pumpAndSettle(defaultOpacityDuration); // Fade in

          // Act
          await tester.pump(defaultAutoHideDuration);
          await tester.pump(defaultOpacityDuration ~/ 2);

          // Assert
          expect(
            renderObject,
            paintsTrackAndThumb(opacity: customCurve.transform(0.5)),
          );
        },
      );
    });

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

    testWidgets(
      'GIVEN theme override '
      'WHEN no local color specified '
      'THEN uses theme colors',
      (tester) async {
        await setUpWidget(tester, thumbColor: null, trackColor: null);
        await tester.pump(defaultOpacityDuration);

        expect(
          getRenderObject(tester),
          paintsTrackAndThumb(
            opacity: 1,
            thumbColor: Theme.of(tester.element(find.byType(ListView)))
                .highlightColor
                .withValues(alpha: 1),
            trackColor:
                Theme.of(tester.element(find.byType(ListView))).highlightColor,
          ),
        );

        await tester.pump(defaultAutoHideDuration);
      },
    );
  });

  group('Configuration changes', () {
    testWidgets(
      'GIVEN active scrollbar '
      'WHEN changing color properties '
      'THEN updates visual appearance',
      (tester) async {
        //Arrange
        await setUpWidget(
          tester,
          thumbColor: Colors.blue,
          trackColor: Colors.green,
        );

        // Act
        await setUpWidget(
          tester,
          thumbColor: Colors.red,
          trackColor: Colors.yellow,
        );

        // Assert
        expect(
          getRenderObject(tester),
          paintsTrackAndThumb(
            opacity: 0,
            thumbColor: Colors.red,
            trackColor: Colors.yellow,
          ),
        );

        await tester.pump(defaultOpacityDuration);
        await tester.pump(defaultAutoHideDuration);
      },
    );

    testWidgets(
      'GIVEN active controller '
      'WHEN swapping controllers '
      'THEN updates scroll tracking',
      (tester) async {
        // Arrange
        final controller1 = ScrollController();
        final controller2 = ScrollController();
        await setUpWidget(tester, controller: controller1);
        final renderObject = getRenderObject(tester);

        //Act
        await setUpWidget(tester, controller: controller2);
        await simulateScrollGesture(tester);

        //Assert
        expect(renderObject, paintsTrackAndThumb(opacity: 0));
        expect(controller1.hasClients, isFalse);
        expect(controller2.hasClients, isTrue);
        expect(controller2.position.extentBefore, greaterThan(0));

        await tester.pump(defaultAutoHideDuration);
      },
    );
  });
}

RenderObject getRenderObject(WidgetTester tester) => tester.renderObject(
      getCustomPaintFinder(),
    );

Finder getCustomPaintFinder() => find.descendant(
      of: find.byType(RoundScrollbar),
      matching: find.byType(CustomPaint),
    );

Future<void> simulateScrollGesture(WidgetTester tester) =>
    tester.scrollUntilVisible(find.byKey(ValueKey(1)), 50);

void animateScrollController(
  ScrollController controller,
  Duration scrollDuration,
) =>
    controller.animateTo(
      controller.offset + 10,
      duration: scrollDuration,
      curve: Curves.linear,
    );

PaintPattern paintsTrackAndThumb({
  required double opacity,
  Color? thumbColor = defaultThumbColor,
  Color? trackColor = defaultTrackColor,
  double width = defaultWidth,
}) =>
    paints
      ..path(
        color: trackColor?.withValues(alpha: trackColor.a * opacity),
        strokeWidth: width,
        style: PaintingStyle.stroke,
      )
      ..path(
        color: thumbColor?.withValues(alpha: thumbColor.a * opacity),
        strokeWidth: width,
        style: PaintingStyle.stroke,
      );
