// Teste básico do MotoHeadApp — verifica se o splash renderiza.
import 'package:flutter_test/flutter_test.dart';

import 'package:motohead_app/main.dart';

void main() {
  testWidgets('App renderiza splash com nome MOTOHEAD', (WidgetTester tester) async {
    await tester.pumpWidget(const MotoHeadApp());
    // Primeiro frame: splash.
    await tester.pump();
    expect(find.text('MOTOHEAD'), findsOneWidget);
  });
}
