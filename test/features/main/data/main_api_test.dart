import 'package:eduma_web/features/main/data/main_space.dart';
import 'package:test/test.dart';

void main() {
  group('MainSpace.fromMap', () {
    test('parses the space fields returned by Eduma', () {
      final space = MainSpace.fromMap({
        '_id': ' space-42 ',
        'title': 'Biology study group',
        'description': 'Shared revision notes',
        'isPinned': true,
        'memberIds': ['user-1', 'user-2'],
        'coverUrl': 'https://cdn.example.com/biology.png',
        'updatedAt': '2026-11-12T10:30:00Z',
      });

      expect(space.id, 'space-42');
      expect(space.title, 'Biology study group');
      expect(space.description, 'Shared revision notes');
      expect(space.isPinned, isTrue);
      expect(space.memberCount, 2);
      expect(space.coverUrl, 'https://cdn.example.com/biology.png');
      expect(space.lastActivity, DateTime.utc(2026, 11, 12, 10, 30));
    });

    test('prefers memberCount when present', () {
      final space = MainSpace.fromMap({
        '_id': 'space-42',
        'title': 'Biology study group',
        'memberCount': 7,
        'memberIds': ['user-1', 'user-2'],
      });

      expect(space.memberCount, 7);
    });

    test('rejects a space without an id or title', () {
      expect(
        () => MainSpace.fromMap({'title': 'Biology study group'}),
        throwsA(isA<MainApiException>()),
      );
      expect(
        () => MainSpace.fromMap({'_id': 'space-42'}),
        throwsA(isA<MainApiException>()),
      );
    });

    test('ignores unsafe cover URLs', () {
      final space = MainSpace.fromMap({
        '_id': 'space-42',
        'title': 'Biology study group',
        'coverUrl': 'javascript:alert(1)',
      });

      expect(space.coverUrl, isNull);
    });
  });
}
