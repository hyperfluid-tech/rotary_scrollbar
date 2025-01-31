[![pub package](https://img.shields.io/pub/v/rotary_scrollbar.svg)](https://pub.dev/packages/rotary_scrollbar)
[![tests](https://github.com/hyperfluid-tech/rotary_scrollbar/actions/workflows/tests.yml/badge.svg)](https://github.com/hyperfluid-tech/rotary_scrollbar/actions/workflows/tests.yml)
[![license](https://img.shields.io/github/license/hyperfluid-tech/rotary_scrollbar)](https://github.com/hyperfluid-tech/rotary_scrollbar/blob/main/LICENSE)
[![code style: flutter_lints](https://img.shields.io/badge/style-%2F%2F%20flutter_lints-40c4ff.svg)](https://pub.dev/packages/flutter_lints)

# rotary_scrollbar


A Flutter package for **Wear OS** that provides a circular scrollbar optimized for rotary input and round screens.  
Enhance scrollable widgets like `ListView`, `PageView`, and `CustomScrollView` with native-feeling interactions. 

![Demo](https://user-images.githubusercontent.com/82336674/208810952-cbd4c983-f48f-4aa6-8f4d-66fe669aeb55.png)

---

## Features

- 🎯 **Native Experience**: Curved scrollbar designed for circular Wear OS displays.  
- 🔄 **Rotary Input**: Full support for rotating bezels/crowns with haptic feedback (via `RotaryScrollbar`).  
- ⚡ **Auto-Hide**: Scrollbar fades after inactivity (configurable duration and animations).  
- 🎨 **Customizable**: Adjust colors, padding, width, and animation curves.  
- 📜 **Scrollable-Ready**: Works with any `ScrollController` or `PageController`.  
- 📱 **Device Support**: Galaxy Watch 4/5, Pixel Watch, and Wear OS 3+ devices.  

---

## RoundScrollbar vs RotaryScrollbar

| Feature                | `RoundScrollbar`          | `RotaryScrollbar`               |  
|------------------------|---------------------------|----------------------------------|  
| **Visual Scrollbar**   | ✅ Curved track/thumb     | ✅ Inherits from `RoundScrollbar`|  
| **Rotary Input**       | ❌                        | ✅ With haptic feedback          |  
| **Page Transitions**   | ❌                        | ✅ Smooth page animations        |  
| **Auto-Hide**          | ✅                        | ✅                                |  

### When to Use  
- **`RotaryScrollbar`**: Default choice for Wear OS apps using rotary input.  
- **`RoundScrollbar`**: For touch-only interactions or custom scroll logic.  

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

---

## Setup

### 1. Add Dependency  
```yaml
dependencies:
  rotary_scrollbar: ^1.1.0
```

### 2. Configuration for Wear OS (Android)

#### Rotary Input ([wearable_rotary](https://pub.dev/packages/wearable_rotary))
Add to `MainActivity.kt`:

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

#### Vibration Permission

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```

---

## Usage

### With `RoundScrollbar` (Basic)
```dart
RoundScrollbar(
  controller: ScrollController(),
  child: ListView.builder(
    itemBuilder: (_, index) => ListTile(title: Text("Item $index")),
  ),
)
```

### With RotaryScrollbar (Full Features)
```dart
RotaryScrollbar(
  controller: PageController(),
  child: PageView(
    children: [Page1(), Page2(), Page3()],
  ),
)
```
---

## Advanced Configuration

### Customize appearance
```dart
RotaryScrollbar(
  width: 12,                  // Thickness
  padding: 16,                // Distance from screen edge
  trackColor: Colors.grey,    // Scrollbar track
  thumbColor: Colors.blue,    // Scrollbar thumb
  autoHideDuration: Duration(seconds: 5),
  // ...other params
)
```

### Disable Haptics
```dart
RotaryScrollbar(
  hasHapticFeedback: false,   // Turn off vibrations
  // ...
)
```
---

## Supported Devices
  - Samsung Galaxy Watch 4/5/6

  - Google Pixel Watch

  - Other Wear OS 3+ devices with rotary input.