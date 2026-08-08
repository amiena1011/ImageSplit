import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ImageSplit/app.dart';

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
