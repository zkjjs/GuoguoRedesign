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

  testWidgets('floating dock switches to the search destination', (tester) async {
    await tester.pumpWidget(const GuoguoApp());

    await tester.tap(find.text('搜索').last);
    await tester.pumpAndSettle();

    expect(find.text('搜索内容'), findsOneWidget);
    expect(find.text('影片、番剧、演员'), findsOneWidget);
  });

  testWidgets('home search field opens the search destination', (tester) async {
    await tester.pumpWidget(const GuoguoApp());

    await tester.tap(find.text('搜索影片、番剧、演员'));
    await tester.pumpAndSettle();

    expect(find.text('搜索内容'), findsOneWidget);
  });
}
