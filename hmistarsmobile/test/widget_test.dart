import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hmistarsmobile/main.dart';

void main() {
  testWidgets('HMI Stars app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HMIStarsApp());
    expect(find.byType(MaterialApp), findsNothing); // GoRouter is used
  });
}
