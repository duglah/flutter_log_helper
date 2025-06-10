# flutter_log_helper

A Flutter package to help you debug and inspect logs, HTTP requests, and navigation actions in your app. It provides an overlay button that, when activated, opens a log viewer with tabs for logs, HTTP requests, and navigation events.

---

## Features

- **Overlay Button:** Attach a floating button to your app to open the log viewer at any time.
- **Log Viewer:** View logs, HTTP requests/responses, and navigation actions in a tabbed interface.
- **Clipboard Support:** Long-press any log entry to copy its content.
- **Share Logs:** Easily share logs using the provided callback.
- **Customizable:** Integrate with your own logging and navigation solutions.

---

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_log_helper:
    git: 
      url: git@github.com:duglah/flutter_log_helper.git
      ref: v0.0.1
```

Import it in your Dart code:

```dart
import 'package:flutter_log_helper/flutter_log_helper.dart';
```

---

## Usage

### 1. Setup Logging and Navigation Observers

```dart
final logInterceptor = LogDioInterceptor();
final navigationObserver = LogNavigatorObserver();
```

### 2. Add the Overlay to Your App

Wrap a widget (e.g., a version label) with `LogOverlay` in your widget tree:

```dart
LogOverlay(
  logs: myLogs, // Iterable<String>
  httpLogCache: logInterceptor.httpLogCache,
  navigationLogCache: navigationObserver.navigationLogCache,
  onSharePressed: () {
    // Implement your share logic
  },
  child: Text('Version: 1.0.0'),
)
```

### 3. Attach the Overlay Button

After tapping the child widget 5 times, the floating overlay button appears. You can also attach it programmatically:

```dart
LogOverlayButton.attach(
  context: context,
  logs: myLogs,
  httpLogCache: logInterceptor.httpLogCache,
  navigationLogCache: navigationObserver.navigationLogCache,
  onSharePressed: () {
    // Implement your share logic
  },
);
```

---

## Example

See the [`/example`](example/) folder for a complete usage example.

---

## Additional Information

- Long-press any log entry to copy it to the clipboard.
- The overlay button can be detached with `LogOverlayButton.detach()`.
- For issues, feature requests, or contributions, please open an issue or pull request on [GitHub](https://github.com/duglah/flutter_log_helper).

---

**Happy debugging!**
