import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_log_helper/flutter_log_helper.dart';

import 'package:example/main.dart';

void main() {
  testWidgets(
    'Should add LogOverlayButton, when Widget wrapped in LogOverlay is pressed 5 times',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(LogOverlayButton), findsNothing);

      // Tap the 'Press me 5 times to attach overlay button.' button five times
      await tester.tap(find.text('Press me 5 times to attach overlay button.'));
      await tester.tap(find.text('Press me 5 times to attach overlay button.'));
      await tester.tap(find.text('Press me 5 times to attach overlay button.'));
      await tester.tap(find.text('Press me 5 times to attach overlay button.'));
      await tester.tap(find.text('Press me 5 times to attach overlay button.'));

      await tester.pump();

      expect(find.byType(LogOverlayButton), findsOneWidget);
    },
  );
}
