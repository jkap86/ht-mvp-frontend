import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hypetrain_mvp/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HypeTrainApp()));

    // Verify app title is displayed
    expect(find.text('HypeTrain FF'), findsAny);
  });
}
