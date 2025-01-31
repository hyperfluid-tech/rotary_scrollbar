[![pub package](https://img.shields.io/pub/v/rotary_scrollbar.svg)](https://pub.dev/packages/rotary_scrollbar)
[![tests](https://github.com/hyperfluid-tech/rotary_scrollbar/actions/workflows/tests.yml/badge.svg)](https://github.com/hyperfluid-tech/rotary_scrollbar/actions/workflows/tests.yml)
[![license](https://img.shields.io/github/license/gilnobrega/rotary_scrollbar)](https://github.com/gilnobrega/rotary_scrollbar/blob/main/LICENSE)
[![code style: flutter_lints](https://img.shields.io/badge/style-%2F%2F%20flutter_lints-40c4ff.svg)](https://pub.dev/packages/flutter_lints)

# rotary_scrollbar

A circular scrollbar for Wear OS Flutter apps, optimized for rotary input and round screens.  
Enhance scrollable views like `ListView` and `PageView` with intuitive scrolling via rotating bezels/crowns.

![Demo](https://user-images.githubusercontent.com/82336674/208810952-cbd4c983-f48f-4aa6-8f4d-66fe669aeb55.png)

## Features

- 🎯 **Native Wear OS Experience**: Curved scrollbar that matches circular displays.
- 🔄 **Rotary Input Support**: Smooth scrolling control with haptic feedback for rotary devices.
- ⚡ **Automatic Behavior**: Auto-hides after inactivity with customizable fade animations.
- 🎨 **Customizable**: Adjust colors, padding, width, and animation curves.
- 📜 **Scrollable Widget Ready**: Works with `ListView`, `PageView`, `CustomScrollView`, and any `ScrollController`/`PageController`.
- 📱 **Device Compatibility**: Galaxy Watch 4/5, Pixel Watch, and other Wear OS 3+ devices.

## Quick Start

### Minimal Example
```dart
RotaryScrollbar(
  controller: ScrollController(),
  child: ListView.builder(
    itemBuilder: (_, index) => ListTile(title: Text('Item $index')),
  ),
)
```

## Setup

### Wear OS (Android)

This package depends on [wearable_rotary](https://pub.dev/packages/wearable_rotary), which requires adding the following to `MainActivity.kt`:

```kotlin
import android.view.MotionEvent
import com.samsung.wearable_rotary.WearableRotaryPlugin

class MainActivity : FlutterActivity() {
    override fun onGenericMotionEvent(event: MotionEvent?): Boolean {
        return when {
            WearableRotaryPlugin.onGenericMotionEvent(event) -> true
            else -> super.onGenericMotionEvent(event)
        }
    }
}
```

This package depends on [vibration](https://pub.dev/packages/vibration), which needs access to the `VIBRATE` permission, so make sure the following is added to `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```

## Usage

To use this plugin, add `rotary_scrollbar` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  rotary_scrollbar: ^1.0.0
```

Then, import `rotary_scrollbar` in your Dart code.

```dart
// Import the package.
import 'package:rotary_scrollbar/rotary_scrollbar.dart';
```

### With ListView
```dart
RotaryScrollbar(
  controller: ScrollController(),
  child: ListView.builder(itemBuilder: ...),
)
```

### With PageView
```dart
RotaryScrollbar(
  controller: PageController(),
  child: PageView(children: [Page1(), Page2()]),
)
```
