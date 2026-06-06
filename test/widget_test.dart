// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co_caro/main.dart';

void main() {
  testWidgets('Caro Game smoke test', (WidgetTester tester) async {
    // Thiết lập kích thước màn hình giả lập lớn hơn để tránh tràn viền khi chạy test
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the game header title is displayed.
    expect(find.text('CARO CHAMPION'), findsOneWidget);

    // Verify that the turn indicator is displayed.
    expect(find.textContaining('Lượt đi:'), findsOneWidget);

    // Verify that the scoreboard labels are displayed.
    expect(find.text('X Thắng'), findsOneWidget);
  });
}
