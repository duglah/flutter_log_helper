import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

enum LogNavigationActionType { push, pop, remove, replace }

class LogNavigationAction {
  final DateTime timestamp = DateTime.now().toUtc();
  final LogNavigationActionType type;
  final String? from;
  final String? to;
  final dynamic args;

  LogNavigationAction({
    required this.type,
    required this.from,
    required this.to,
    this.args,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LogNavigationAction &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            const DeepCollectionEquality().equals(other.args, args));
  }

  @override
  int get hashCode => Object.hash(runtimeType, type, from, to, args);

  @override
  String toString() {
    return 'LogNavigationAction(type: $type, from: $from, to: $to, args: $args at $timestamp)';
  }
}

class LogNavigatorObserver extends NavigatorObserver {
  final void Function(LogNavigationAction action)? _logCallback;

  final int _maxCacheSize;

  /// A cache for logged requests and responses.
  final List<LogNavigationAction> navigationLogCache = [];

  LogNavigatorObserver({
    void Function(LogNavigationAction action)? callback,
    int maxCacheSize = 100,
  }) : _maxCacheSize = maxCacheSize,
       assert(maxCacheSize > 0, 'maxCacheSize must be greater than 0'),
       _logCallback = callback;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(
      LogNavigationAction(
        type: LogNavigationActionType.push,
        from: previousRoute?.settings.name,
        to: route.settings.name,
        args: route.settings.arguments,
      ),
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(
      LogNavigationAction(
        type: LogNavigationActionType.pop,
        from: previousRoute?.settings.name,
        to: route.settings.name,
        args: route.settings.arguments,
      ),
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(
      LogNavigationAction(
        type: LogNavigationActionType.remove,
        from: previousRoute?.settings.name,
        to: route.settings.name,
        args: route.settings.arguments,
      ),
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _log(
      LogNavigationAction(
        type: LogNavigationActionType.replace,
        from: oldRoute?.settings.name,
        to: newRoute?.settings.name,
        args: newRoute?.settings.arguments,
      ),
    );
  }

  void _log(LogNavigationAction action) {
    if (navigationLogCache.length >= _maxCacheSize) {
      navigationLogCache.removeAt(0);
    }
    navigationLogCache.add((action));

    if (_logCallback != null) {
      _logCallback(action);
    }
  }
}
