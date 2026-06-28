import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_caro/profile_page.dart';

void main() {
  testWidgets('Test validate cac truong nhap lieu trong ProfilePage', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ProfilePage(),
    ));

    // Tim nut Doi mat khau qua Icon vpn_key va nhan
    final submitButton = find.byIcon(Icons.vpn_key);
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Kiem tra cac thong bao loi validator mac dinh
    expect(find.text('Vui lòng nhập mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu mới'), findsOneWidget);

    // Nhap mat khau moi duoi 6 ky tu
    final newPasswordInput = find.widgetWithText(TextFormField, 'Mật khẩu mới');
    await tester.enterText(newPasswordInput, '123');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu mới phải có ít nhất 6 ký tự'), findsOneWidget);

    // Nhap mat khau xac nhan khong khop
    await tester.enterText(newPasswordInput, '123456');
    final confirmPasswordInput = find.widgetWithText(TextFormField, 'Nhập lại mật khẩu mới');
    await tester.enterText(confirmPasswordInput, '123457');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu xác nhận không khớp!'), findsOneWidget);
  });
}
