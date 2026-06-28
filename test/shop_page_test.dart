import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_caro/shop_page.dart';
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
  FakeGoTrueClient() : super(url: 'http://localhost:3000', headers: {});

  @override
  User? get currentUser => FakeUser();

  @override
  void startAutoRefresh() {}

  @override
  void stopAutoRefresh() {}
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
  testWidgets('Test widget ShopPage layout renders properly', (WidgetTester tester) async {
    final fakeAuth = FakeGoTrueClient();
    final fakeSupabase = FakeSupabaseClient(fakeAuth);

    await tester.pumpWidget(MaterialApp(
      home: ShopPage(
        supabaseClient: fakeSupabase,
        initialDiamonds: 100,
        initialUnlockedIcons: const ['X', 'O', '⭐'],
        initialSelectedIcon: 'X',
      ),
    ));

    // Verify diamond balance shows up
    expect(find.text('100'), findsWidgets);
    
    // Verify currently unlocked icons render
    expect(find.text('⭐'), findsWidgets);
    
    // Verify shop items render
    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('👑'), findsOneWidget);
  });
}
