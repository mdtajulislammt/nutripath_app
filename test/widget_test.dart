import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutripath/main.dart';
import 'package:nutripath/providers/app_state_provider.dart';

void main() {
  testWidgets('NutriPath smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStateProvider(),
        child: const NutriPathApp(),
      ),
    );
    expect(find.byType(NutriPathApp), findsOneWidget);
  });
}
