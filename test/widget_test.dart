import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pedrapp/features/pomodoro/pomodoro_pantalla.dart';

void main() {
  testWidgets('shows configurable pomodoro default durations', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PomodoroPantalla()));

    expect(find.text('40 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('40:00'), findsOneWidget);
  });
}
