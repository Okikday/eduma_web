import 'package:test/test.dart';

import 'package:eduma_web/features/space/data/space_detail_models.dart';

void main() {
  group('SpaceDetail models & permissions', () {
    test('SpacePermissionsLogic derives owner, admin, member, and personal rules', () {
      final space = SpaceDetailData.fromMap({
        '_id': 'sp-1',
        'ownerId': 'u-owner',
        'title': 'Biology',
        'admins': ['u-admin'],
        'memberCount': 5,
        'settings': {
          'membersCanEditDetails': false,
          'membersCanAddPages': true,
          'membersCanInvite': false,
        },
      });

      final owner = SpacePermissionsLogic(space: space, currentUserId: 'u-owner');
      expect(owner.role, SpaceDetailRole.owner);
      expect(owner.canEditSpaceDetails, isTrue);
      expect(owner.canInvite, isTrue);
      expect(owner.canRenewInvite, isTrue);

      final admin = SpacePermissionsLogic(space: space, currentUserId: 'u-admin');
      expect(admin.role, SpaceDetailRole.admin);
      expect(admin.canManageMembers, isTrue);

      final member = SpacePermissionsLogic(space: space, currentUserId: 'u-member');
      expect(member.role, SpaceDetailRole.member);
      expect(member.canEditSpaceDetails, isFalse);
      expect(member.canAddPages, isTrue);
      expect(member.canInvite, isFalse);
      expect(member.canRenewInvite, isFalse);

      final personal = SpaceDetailData.fromMap({
        '_id': 'sp-personal',
        'ownerId': 'u-owner',
        'title': 'My space',
        'kind': 'personal',
      });
      final personalOwner = SpacePermissionsLogic(space: personal, currentUserId: 'u-owner');
      expect(personalOwner.isPersonal, isTrue);
      expect(personalOwner.canInvite, isFalse);
      expect(personalOwner.canManageMembers, isFalse);
    });

    test('SpacePageQuery filters by type, archived flag, and search query', () {
      final pages = [
        SpacePage.fromMap({
          '_id': 'p1',
          'title': 'Cell Membrane',
          'description': 'Phospholipids',
          'pageType': 'dynamicCanvas',
        }),
        SpacePage.fromMap({
          '_id': 'p2',
          'title': 'Lab Syllabus',
          'pageType': 'staticPage',
        }),
        SpacePage.fromMap({
          '_id': 'p3',
          'title': 'Old Notes',
          'pageType': 'staticPage',
          'isArchived': true,
        }),
      ];

      expect(
        SpacePageQuery.apply(pages, filter: .all).map((p) => p.id),
        ['p1', 'p2'],
      );
      expect(
        SpacePageQuery.apply(pages, filter: .canvas).map((p) => p.id),
        ['p1'],
      );
      expect(
        SpacePageQuery.apply(pages, filter: .notes).map((p) => p.id),
        ['p2'],
      );
      expect(
        SpacePageQuery.apply(pages, filter: .archived).map((p) => p.id),
        ['p3'],
      );
      expect(
        SpacePageQuery.apply(pages, filter: .all, query: 'phospho').map((p) => p.id),
        ['p1'],
      );
    });

    test('SpaceInviteExpiryLogic formats remaining days accurately', () {
      final now = DateTime(2026, 6, 10, 12);
      expect(SpaceInviteExpiryLogic.label(null, now: now), isNull);
      expect(
        SpaceInviteExpiryLogic.label(DateTime(2026, 6, 10, 11), now: now),
        'Expired',
      );
      expect(
        SpaceInviteExpiryLogic.label(DateTime(2026, 6, 10, 23), now: now),
        'Expires today',
      );
      expect(
        SpaceInviteExpiryLogic.label(DateTime(2026, 6, 11, 10), now: now),
        'Expires tomorrow',
      );
      expect(
        SpaceInviteExpiryLogic.label(DateTime(2026, 6, 15, 10), now: now),
        'Expires in 5 days',
      );
    });
  });
}
