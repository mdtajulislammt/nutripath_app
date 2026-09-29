import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nutripath/main.dart';
import 'package:nutripath/providers/app_state_provider.dart';

void main() {
  testWidgets('NutriPath 4-tab navigation and history test', (WidgetTester tester) async {
    final provider = AppStateProvider();
    await provider.signInWithGoogle(email: 'test@example.com', name: 'Tester');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const NutriPathApp(),
      ),
    );

    // Initial load reaches Splash, wait for splash timer
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Today screen is visible
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    // Tap on History tab
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    // Verify Diet History screen is visible
    expect(find.text('Diet History'), findsOneWidget);
    expect(find.textContaining('on Diet'), findsOneWidget);

    // Tap on a day card to open Day Details Modal
    final yesterdayCard = find.textContaining('Yesterday');
    if (yesterdayCard.evaluate().isNotEmpty) {
      await tester.tap(yesterdayCard.first);
      await tester.pumpAndSettle();
      expect(find.text('Breakfast'), findsWidgets);
      // Close sheet
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    }

    // Tap on AI Chat tab
    await tester.tap(find.text('AI Chat'));
    await tester.pumpAndSettle();

    // Verify AI Chat screen is visible
    expect(find.text('NutriPath AI পুষ্টিবিদ'), findsOneWidget);
    expect(find.textContaining('বাংলায়'), findsWidgets);

    // Tap on a quick question chip
    final chip = find.text('১ প্লেট ভাতে কত ক্যালোরি?');
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Verify AI responded in Bengali
    expect(find.textContaining('ক্যালোরি'), findsWidgets);

    // Tap on Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    // Verify Profile screen and Google login
    expect(find.text('Profile'), findsWidgets);
    expect(find.textContaining('Google'), findsWidgets);
  });
}
