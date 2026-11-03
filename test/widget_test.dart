import 'package:flutter_test/flutter_test.dart';
import 'package:school_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // بناء التطبيق وإطلاق أول إطار
    await tester.pumpWidget(const SchoolApp());

    // التأكد من تحميل واجهة التطبيق بنجاح
    expect(find.byType(SchoolApp), findsOneWidget);
  });
}
