import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/main.dart';

void main() {
  testWidgets('GuoguoApp renders four navigation destinations', (tester) async {
    await tester.pumpWidget(const GuoguoApp());

    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });
}
