# rotary_scrollbar
Flutter implementation of a rounded scrollbar for wearOS devices with round screens

Also listens to rotary input and provides haptic feedback.


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
  rotary_scrollbar: ^0.1.0
```

Then, import `wrotary_scrollbar` in your Dart code.

```dart
// Import the package.
import 'package:rotary_scrollbar/rotary_scrollbar.dart';

```

## Supported devices

- Wear OS devices with rotary input (Galaxy Watch 4, Pixel Watch, etc.)
