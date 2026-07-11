import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trreee/main.dart';

void main() {
  testWidgets('Trreee app builds without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TrreeeApp()),
    );
    expect(tester.takeException(), isNull);
  });
}
