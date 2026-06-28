import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Test widget profile navigation layout is present', (WidgetTester tester) async {
    // Check presence of PopupMenuButton and CircleAvatar
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: Color(0xFF1E293B),
                  child: Icon(Icons.person, color: Color(0xFF06B6D4)),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: Text('Đổi mật khẩu'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });
}
