import 'package:flutter/material.dart';
import 'package:flutter_log_helper/src/log_navigation_observer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogNavigationAction', () {
    group('==', () {
      test('should return true for identical objects', () {
        final action1 = LogNavigationAction(
          type: LogNavigationActionType.push,
          from: 'Page1',
          to: 'Page2',
          args: 'arg',
        );
        final action2 = LogNavigationAction(
          type: LogNavigationActionType.push,
          from: 'Page1',
          to: 'Page2',
          args: 'arg',
        );

        expect(action1, action2);
      });

      test('should return false for different types', () {
        final action = LogNavigationAction(
          type: LogNavigationActionType.push,
          from: 'Page1',
          to: 'Page2',
          args: 'arg',
        );

        expect(action, isNot('not a LogNavigationAction'));
      });
    });
  });
  group('LogNavigatorObserver', () {
    group('logCache', () {
      test('should add didPush action to logCache', () {
        final observer = LogNavigatorObserver();

        observer.didPush(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        final navAction = observer.navigationLogCache.last;

        expect(navAction.type, LogNavigationActionType.push);
        expect(navAction.from, 'PageFrom');
        expect(navAction.to, 'PageTo');
        expect(navAction.args, 'argTo');
      });

      test('should pass didPop action to callback', () {
        final observer = LogNavigatorObserver();

        observer.didPop(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        final navAction = observer.navigationLogCache.last;

        expect(navAction.type, LogNavigationActionType.pop);
        expect(navAction.from, 'PageFrom');
        expect(navAction.to, 'PageTo');
        expect(navAction.args, 'argTo');
      });

      test('should pass didRemove action to callback', () {
        final observer = LogNavigatorObserver();

        observer.didRemove(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        final navAction = observer.navigationLogCache.last;

        expect(navAction.type, LogNavigationActionType.remove);
        expect(navAction.from, 'PageFrom');
        expect(navAction.to, 'PageTo');
        expect(navAction.args, 'argTo');
      });

      test('should pass didRemove action to callback', () {
        final observer = LogNavigatorObserver();

        observer.didReplace(
          newRoute: MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          oldRoute: MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        final navAction = observer.navigationLogCache.last;

        expect(navAction.type, LogNavigationActionType.replace);
        expect(navAction.from, 'PageFrom');
        expect(navAction.to, 'PageTo');
        expect(navAction.args, 'argTo');
      });

      test('should not exceed maxCacheSize', () {
        final observer = LogNavigatorObserver(maxCacheSize: 2);

        observer.didPush(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'Page1', arguments: 'arg1'),
          ),
          null,
        );
        observer.didPush(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'Page2', arguments: 'arg2'),
          ),
          null,
        );
        observer.didPush(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'Page3', arguments: 'arg3'),
          ),
          null,
        );

        expect(observer.navigationLogCache.length, 2);
        expect(observer.navigationLogCache.first.to, 'Page2');
        expect(observer.navigationLogCache.last.to, 'Page3');
      });
    });

    group('callback', () {
      test('should pass didPush action to callback', () {
        LogNavigationAction? navAction;
        final observer = LogNavigatorObserver(
          callback: (action) {
            navAction = action;
          },
        );

        observer.didPush(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        expect(navAction, isNotNull);
        expect(navAction!.type, LogNavigationActionType.push);
        expect(navAction!.from, 'PageFrom');
        expect(navAction!.to, 'PageTo');
        expect(navAction!.args, 'argTo');
      });

      test('should pass didPop action to callback', () {
        LogNavigationAction? navAction;
        final observer = LogNavigatorObserver(
          callback: (action) {
            navAction = action;
          },
        );

        observer.didPop(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        expect(navAction, isNotNull);
        expect(navAction!.type, LogNavigationActionType.pop);
        expect(navAction!.from, 'PageFrom');
        expect(navAction!.to, 'PageTo');
        expect(navAction!.args, 'argTo');
      });

      test('should pass didRemove action to callback', () {
        LogNavigationAction? navAction;
        final observer = LogNavigatorObserver(
          callback: (action) {
            navAction = action;
          },
        );

        observer.didRemove(
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        expect(navAction, isNotNull);
        expect(navAction!.type, LogNavigationActionType.remove);
        expect(navAction!.from, 'PageFrom');
        expect(navAction!.to, 'PageTo');
        expect(navAction!.args, 'argTo');
      });

      test('should pass didRemove action to callback', () {
        LogNavigationAction? navAction;
        final observer = LogNavigatorObserver(
          callback: (action) {
            navAction = action;
          },
        );

        observer.didReplace(
          newRoute: MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageTo', arguments: 'argTo'),
          ),
          oldRoute: MaterialPageRoute(
            builder: (context) => Container(),
            settings: RouteSettings(name: 'PageFrom', arguments: 'argFrom'),
          ),
        );

        expect(navAction, isNotNull);
        expect(navAction!.type, LogNavigationActionType.replace);
        expect(navAction!.from, 'PageFrom');
        expect(navAction!.to, 'PageTo');
        expect(navAction!.args, 'argTo');
      });
    });
  });
}
