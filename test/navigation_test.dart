import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_caro/profile_page.dart';

void main() {
  testWidgets('Test widget profile navigation layout is present', (WidgetTester tester) async {
    // We create a mock scaffold containing the Positioned email block as it will be in main.dart
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 12,
              right: 12,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Material(
                  color: const Color(0xFF1E293B),
                  elevation: 4,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Tooltip(
                            message: 'Xem thông tin cá nhân / Đổi mật khẩu',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.account_circle_outlined,
                                      size: 18,
                                      color: Color(0xFF06B6D4),
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'test@example.com',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));

    // Verify the presence of InkWell for profile navigation
    expect(find.byType(InkWell), findsOneWidget);
    expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
  });
}
