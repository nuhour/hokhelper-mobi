import 'package:flutter_test/flutter_test.dart';

import 'package:hok_helper_mobile/main.dart';

void main() {
  testWidgets('shows bootstrap title', (WidgetTester tester) async {
    await tester.pumpWidget(const HokHelperBootstrap());

    expect(find.text('HOK Helper Mobile'), findsOneWidget);
  });
}
