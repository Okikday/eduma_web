import 'package:eduma_web/features/main/data/main_canvas.dart';
import 'package:eduma_web/features/main/data/main_space.dart';
import 'package:eduma_web/features/main/logic/main_space_query.dart';
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
        'lastEditedAt': '2026-11-12T10:30:00Z',
      });

      expect(space.id, 'space-42');
      expect(space.title, 'Biology study group');
      expect(space.description, 'Shared revision notes');
      expect(space.isPinned, isTrue);
      expect(space.memberCount, 2);
      expect(space.coverUrl, 'https://cdn.example.com/biology.png');
      expect(space.lastActivity, DateTime.utc(2026, 11, 12, 10, 30));
      expect(space.activityType, MainSpaceActivityType.edited);
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

    test('maps role, verification, personal spaces, and member previews', () {
      final space = MainSpace.fromMap({
        '_id': 'space-42',
        'ownerId': 'user-1',
        'title': 'Biology study group',
        'kind': 'personal',
        'isVerified': true,
        'memberIds': [
          {
            '_id': 'user-2',
            'name': 'Ada Learner',
            'avatarUrl': 'https://cdn.example.com/ada.png',
          },
        ],
      }, currentUserId: 'user-1');

      expect(space.role, MainSpaceRole.owner);
      expect(space.isVerified, isTrue);
      expect(space.isPersonal, isTrue);
      expect(space.memberPreview.single.name, 'Ada Learner');
      expect(
        space.memberPreview.single.avatarUrl,
        'https://cdn.example.com/ada.png',
      );
    });

    test('matches invite visibility with role and space settings', () {
      final memberRestricted = MainSpace.fromMap({
        '_id': 'space-member',
        'title': 'Biology study group',
        'settings': {'membersCanInvite': false},
      });
      final memberAllowed = MainSpace.fromMap({
        '_id': 'space-member-allowed',
        'title': 'Chemistry study group',
        'settings': {'membersCanInvite': true},
      });
      final adminRestricted = MainSpace.fromMap({
        '_id': 'space-admin',
        'title': 'Physics study group',
        'role': 'admin',
        'settings': {'membersCanInvite': false},
      });
      final personal = MainSpace.fromMap({
        '_id': 'space-personal',
        'title': 'My space',
        'kind': 'personal',
        'role': 'owner',
      });

      expect(memberRestricted.canInvite, isFalse);
      expect(memberAllowed.canInvite, isTrue);
      expect(adminRestricted.canInvite, isTrue);
      expect(personal.canInvite, isFalse);
      expect(
        MainSpace.fromMap({
          '_id': 'space-default',
          'title': 'Default settings',
        }).canInvite,
        isTrue,
      );
    });
  });

  group('MainCanvas.tryParse', () {
    test('parses a wrapped recent canvas and its Flutter deep-link data', () {
      final canvas = MainCanvas.tryParse({
        'pageId': 'page-1',
        'spaceId': 'space-1',
        'openedAt': '2026-11-12T10:30:00Z',
        'page': {
          '_id': 'page-1',
          'title': 'Revision notes',
          'pageType': 'staticPage',
          'previewUrl': 'https://cdn.example.com/preview.png',
          'updatedAt': '2026-11-11T08:00:00Z',
        },
        'space': {'title': 'Biology'},
      });

      expect(canvas, isNotNull);
      expect(canvas!.id, 'page-1');
      expect(canvas.spaceId, 'space-1');
      expect(canvas.type, MainCanvasType.staticPage);
      expect(canvas.title, 'Revision notes');
      expect(canvas.spaceTitle, 'Biology');
      expect(canvas.previewUrl, 'https://cdn.example.com/preview.png');
      expect(canvas.openedAt, DateTime.utc(2026, 11, 12, 10, 30));
    });

    test('parses bare dynamic canvases and ignores deleted or invalid pages', () {
      final canvas = MainCanvas.tryParse({
        '_id': 'page-2',
        'spaceId': 'space-2',
        'title': 'Study canvas',
        'pageType': 'dynamicCanvas',
      });

      expect(canvas?.type, MainCanvasType.dynamicCanvas);
      expect(
        MainCanvas.tryParse({
          'pageId': 'deleted',
          'spaceId': 'space-2',
          'deleted': true,
        }),
        isNull,
      );
      expect(MainCanvas.tryParse({'title': 'Missing identity'}), isNull);
    });

    test('ignores unsafe preview URLs', () {
      final canvas = MainCanvas.tryParse({
        '_id': 'page-3',
        'spaceId': 'space-3',
        'previewUrl': 'javascript:alert(1)',
      });

      expect(canvas?.previewUrl, isNull);
    });
  });

  group('MainSpaceQuery.apply', () {
    final spaces = [
      MainSpace.fromMap({
        '_id': 'space-b',
        'ownerId': 'user-1',
        'title': 'Beta',
        'createdAt': '2026-01-01T00:00:00Z',
        'updatedAt': '2026-03-01T00:00:00Z',
        'lastAccessedAt': '2026-03-02T00:00:00Z',
      }, currentUserId: 'user-1'),
      MainSpace.fromMap({
        '_id': 'space-a',
        'ownerId': 'user-2',
        'title': 'Alpha',
        'isPinned': true,
        'createdAt': '2026-02-01T00:00:00Z',
        'updatedAt': '2026-04-01T00:00:00Z',
        'lastAccessedAt': '2026-02-20T00:00:00Z',
      }, currentUserId: 'user-1'),
    ];

    test('filters owned, joined, and pinned spaces', () {
      expect(
        MainSpaceQuery.apply(spaces, filter: .owned).map((space) => space.id),
        ['space-b'],
      );
      expect(
        MainSpaceQuery.apply(spaces, filter: .joined).map((space) => space.id),
        ['space-a'],
      );
      expect(
        MainSpaceQuery.apply(spaces, filter: .pinned).map((space) => space.id),
        ['space-a'],
      );
    });

    test('sorts by name, creation, and access while keeping input immutable', () {
      expect(
        MainSpaceQuery.apply(spaces).map((space) => space.id),
        ['space-a', 'space-b'],
      );
      expect(
        MainSpaceQuery.apply(spaces, sort: .name).map((space) => space.id),
        ['space-a', 'space-b'],
      );
      expect(
        MainSpaceQuery.apply(spaces, sort: .date).map((space) => space.id),
        ['space-a', 'space-b'],
      );
      expect(
        MainSpaceQuery.apply(spaces, sort: .accessed).map((space) => space.id),
        ['space-b', 'space-a'],
      );
      expect(spaces.map((space) => space.id), ['space-b', 'space-a']);
    });

    test('keeps personal spaces first and sorting stable for equal keys', () {
      final personal = MainSpace.fromMap({
        '_id': 'personal',
        'title': 'Zeta',
        'kind': 'personal',
        'createdAt': '2025-01-01T00:00:00Z',
      });
      final first = MainSpace.fromMap({
        '_id': 'first',
        'title': 'Alpha',
        'createdAt': '2025-01-01T00:00:00Z',
      });
      final second = MainSpace.fromMap({
        '_id': 'second',
        'title': 'Alpha',
        'createdAt': '2025-01-01T00:00:00Z',
      });

      expect(
        MainSpaceQuery.apply([second, personal, first], sort: .name).map((space) => space.id),
        ['personal', 'second', 'first'],
      );
    });
  });
}
