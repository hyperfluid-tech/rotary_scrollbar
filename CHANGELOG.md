## 1.1.1

- **Bug Fixes**:
  - Fixed `AnimationController.reverse() called after AnimationController.dispose()` when a page with a
    `RoundScrollbar` is closed before the auto-hide duration elapses. The fade-out timer is now cancelled in
    `dispose()` and its callback checks `mounted`.

## 1.1.0

- **Bug Fixes**:
  - Made scrollbar not visible when content isn't scrollable.
  - Improved dependency handling and controller lifecycle management.

- **Other changes**:
  - Added detailed API docs for `RoundScrollbar` and `RotaryScrollbar`.
  - Added comprehensive widget tests for scrollbar behavior, animations, and edge cases.

## 1.0.0

- Fixed issue [#7](../../issues/7) - Scrollbar not showing on new page.
- Improved performance of `RoundScrollbar` and `RotaryScrollbar`.
- Updated documentation and examples.
- Removed `RotaryScrollWrapper`. This widget is no longer necessary.

## 0.1.1

- Improved documentation.
- Provided `example/list_view.dart`.
- Provided `example/page_view.dart`.

## 0.1.0

- Initial Release.
