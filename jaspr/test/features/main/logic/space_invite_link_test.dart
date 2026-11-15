import 'package:test/test.dart';

import 'package:eduma_web/features/main/data/main_space.dart';
import 'package:eduma_web/features/main/data/main_space_mutations.dart';
import 'package:eduma_web/features/main/logic/space_invite_link.dart';

void main() {
  group('SpaceInviteLink', () {
    test('extractCode accepts raw invite codes and trims whitespace', () {
      expect(SpaceInviteLink.extractCode('  SPC-4982  '), 'SPC-4982');
      expect(SpaceInviteLink.extractCode('   '), '');
    });

    test('extractCode extracts invite code from shareable URLs', () {
      expect(
        SpaceInviteLink.extractCode('https://eduma.app/join/SPC-4982'),
        'SPC-4982',
      );
      expect(
        SpaceInviteLink.extractCode('https://eduma.app/join/abc123?ref=copy#top'),
        'abc123',
      );
      expect(
        SpaceInviteLink.extractCode('/join/code-9/extra'),
        'code-9',
      );
    });

    test('expiredErrorMessage matches 410 or INVITE_EXPIRED', () {
      expect(
        SpaceInviteLink.expiredErrorMessage(statusCode: 410),
        SpaceInviteLink.expiredInviteMessage,
      );
      expect(
        SpaceInviteLink.expiredErrorMessage(code: 'invite_expired'),
        SpaceInviteLink.expiredInviteMessage,
      );
      expect(SpaceInviteLink.expiredErrorMessage(statusCode: 404, code: 'NOT_FOUND'), isNull);
    });
  });

  group('MainSpace mutations models', () {
    test('MainSpacePreview parses member, verification, and cover fields', () {
      final preview = MainSpacePreview.fromMap({
        'spaceId': 'sp-1',
        'title': 'Organic Chemistry',
        'description': 'Weekly lab group',
        'memberCount': 14,
        'ownerName': 'Ada',
        'alreadyMember': true,
        'verified': true,
        'coverImage': 'https://cdn.eduma.test/cover.jpg',
      });

      expect(preview.spaceId, 'sp-1');
      expect(preview.title, 'Organic Chemistry');
      expect(preview.description, 'Weekly lab group');
      expect(preview.memberCount, 14);
      expect(preview.ownerName, 'Ada');
      expect(preview.alreadyMember, isTrue);
      expect(preview.isVerified, isTrue);
      expect(preview.coverUrl, 'https://cdn.eduma.test/cover.jpg');
    });

    test('MainSpaceJoinResult distinguishes joined vs pending requests', () {
      final pending = MainSpaceJoinResult.fromMap({
        'status': 'pending',
        'requestId': 'req-42',
        'spaceId': 'sp-1',
      });
      expect(pending.pending, isTrue);
      expect(pending.requestId, 'req-42');
      expect(pending.spaceId, 'sp-1');

      final joined = MainSpaceJoinResult.fromMap({
        'status': 'joined',
        'space': {
          '_id': 'sp-2',
          'title': 'Calculus II',
          'memberCount': 3,
        },
      });
      expect(joined.pending, isFalse);
      expect(joined.spaceId, 'sp-2');
      expect(joined.space?.title, 'Calculus II');
    });

    test('MainSpace.copyWith updates pin state while keeping identity', () {
      final space = MainSpace.fromMap({
        '_id': 'sp-9',
        'title': 'Physics',
        'isPinned': false,
        'memberCount': 5,
      });
      final pinned = space.copyWith(isPinned: true);
      expect(pinned.id, 'sp-9');
      expect(pinned.title, 'Physics');
      expect(pinned.isPinned, isTrue);
      expect(pinned.memberCount, 5);
    });
  });
}
