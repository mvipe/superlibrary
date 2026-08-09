// Basic smoke test for SuperLibrary.
//
// Verifies the app boots without throwing during the first frame.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_library/main.dart';

void main() {
  testWidgets('App boots to a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const SuperLibraryApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
