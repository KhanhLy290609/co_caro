import 'package:co_caro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: 'https://caddicxvszitasqahdck.supabase.co',
      publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhZGRpY3h2c3ppdGFzcWFoZGNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MTcwMjYsImV4cCI6MjA5NjI5MzAyNn0.GmPJHIrFkFtruwmqsQioDN2atv1VApV68y_qG1dd4TA',
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MyApp());

    expect(find.text('Đăng nhập'), findsAtLeastNWidgets(1));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await Supabase.instance.dispose();
  });
}
