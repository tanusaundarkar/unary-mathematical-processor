
import 'package:flutter_test/flutter_test.dart';
import 'package:unary_tm/main.dart';

void main() {
  testWidgets('Unary Mathematical Processor launches', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UnaryApp());
    expect(find.text('Unary Mathematical Processor'), findsOneWidget);
  });
}
