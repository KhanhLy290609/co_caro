import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_caro/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeUser extends User {
  FakeUser()
      : super(
          id: 'fake-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'aud',
          createdAt: DateTime.now().toIso8601String(),
          email: 'test@example.com',
        );
}

class FakeGoTrueClient extends GoTrueClient {
  bool signInCalled = false;
  bool updateUserCalled = false;
  bool signOutCalled = false;
  bool shouldFailSignIn = false;

  FakeGoTrueClient() : super(url: 'http://localhost:3000', headers: {});

  @override
  User? get currentUser => FakeUser();

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    required String password,
    String? phone,
    String? captchaToken,
  }) async {
    signInCalled = true;
    if (shouldFailSignIn) {
      throw const AuthException('Mật khẩu hiện tại không chính xác');
    }
    return AuthResponse(session: Session(accessToken: 'token', tokenType: 'bearer', user: FakeUser()));
  }

  @override
  Future<UserResponse> updateUser(
    UserAttributes attributes, {
    String? emailRedirectTo,
  }) async {
    updateUserCalled = true;
    return UserResponse.fromJson({
      'id': 'fake-id',
      'email': 'test@example.com',
    });
  }

  @override
  void startAutoRefresh() {}

  @override
  void stopAutoRefresh() {}

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    signOutCalled = true;
  }
}

class FakeSupabaseClient implements SupabaseClient {
  final FakeGoTrueClient _fakeAuth;

  FakeSupabaseClient(this._fakeAuth);

  @override
  GoTrueClient get auth => _fakeAuth;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  testWidgets('Test logic doi mat khau thanh cong', (WidgetTester tester) async {
    final fakeAuth = FakeGoTrueClient();
    final fakeSupabase = FakeSupabaseClient(fakeAuth);

    await tester.pumpWidget(MaterialApp(
      home: ProfilePage(supabaseClient: fakeSupabase),
    ));

    await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu hiện tại'), 'current_pwd');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu mới'), 'new_pwd_123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nhập lại mật khẩu mới'), 'new_pwd_123');

    await tester.tap(find.byIcon(Icons.vpn_key));
    await tester.pump();

    // Verify rang signInWithPassword & updateUser duoc goi
    expect(fakeAuth.signInCalled, true);
    // Vi Task 2 chua implement logic nen thong tin nay tam thoi fail o day
    expect(fakeAuth.updateUserCalled, true);
  });
}
