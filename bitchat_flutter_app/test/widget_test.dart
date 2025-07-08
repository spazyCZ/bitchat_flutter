import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  group('BitchatApp Widget Tests', () {
    testWidgets('App should launch and show correct title', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const BitchatApp());

      // Verify that the app bar shows the correct title
      expect(find.text('bitchat*'), findsOneWidget);
      
      // Verify the dark theme is applied
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.brightness, equals(Brightness.dark));
      expect(app.theme?.scaffoldBackgroundColor, equals(Colors.black));
    });

    testWidgets('App should show initialization screen initially', (WidgetTester tester) async {
      await tester.pumpWidget(const BitchatApp());

      // Should show loading indicator during initialization
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing bitchat*...'), findsOneWidget);
    });

    testWidgets('App should have monospace font theme', (WidgetTester tester) async {
      await tester.pumpWidget(const BitchatApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      final textTheme = app.theme?.textTheme;
      
      expect(textTheme?.bodyLarge?.fontFamily, equals('monospace'));
      expect(textTheme?.bodyMedium?.fontFamily, equals('monospace'));
      expect(textTheme?.bodyLarge?.color, equals(Colors.green));
    });
  });
}