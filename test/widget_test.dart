import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guoguo/main.dart';

void main() {
  testWidgets('renders the Apple glass home screen', (tester) async {
    await tester.pumpWidget(const GuoguoApp());

    expect(find.text('首页'), findsWidgets);
    expect(find.text('继续观看'), findsOneWidget);
    expect(find.text('我的媒体'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('floating dock updates the selected item', (tester) async {
    await tester.pumpWidget(const GuoguoApp());

    await tester.tap(find.text('搜索').last);
    await tester.pumpAndSettle();

    final searchIcons = tester.widgetList<Icon>(
      find.byIcon(CupertinoIcons.search),
    );
    expect(searchIcons.any((icon) => icon.color == const Color(0xFF007AFF)), isTrue);
  });
}
