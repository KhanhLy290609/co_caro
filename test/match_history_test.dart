import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_caro/main.dart';

void main() {
  test('Test MatchRecord toJson and fromJson serialization', () {
    final record = MatchRecord(
      opponent: 'Bot AI (Khó)',
      mode: 'vs_bot',
      result: 'win',
      playedAt: DateTime(2026, 6, 28, 22, 50),
    );

    final json = record.toJson();
    expect(json['opponent'], 'Bot AI (Khó)');
    expect(json['mode'], 'vs_bot');
    expect(json['result'], 'win');

    final parsed = MatchRecord.fromJson(json);
    expect(parsed.opponent, 'Bot AI (Khó)');
    expect(parsed.mode, 'vs_bot');
    expect(parsed.result, 'win');
    expect(parsed.playedAt.year, 2026);
  });
}
