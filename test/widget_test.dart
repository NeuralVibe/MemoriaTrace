// This is a basic Flutter widget test for MemoriaTrace app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_trace/main.dart';

void main() {
  testWidgets('MemoriaTrace app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemoriaTraceApp());

    // Verify that our app title appears.
    expect(find.text('MemoriaTrace'), findsOneWidget);

    // Verify that the permission status message appears.
    expect(find.textContaining('권한'), findsAtLeastNWidgets(1));

    // Verify that the app has a permission request button when needed.
    expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
  });
}
