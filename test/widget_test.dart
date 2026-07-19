import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/main.dart';

void main() {
  testWidgets('GuoguoApp renders the required default navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const GuoguoApp());

    expect(find.byType(NavigationDestination), findsNWidgets(4));

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    final labels = navigationBar.destinations.cast<NavigationDestination>().map(
      (destination) => destination.label,
    );

    expect(labels, orderedEquals(['频道', '搜索', '收藏', '我的']));
    expect(navigationBar.selectedIndex, 0);
  });
}
