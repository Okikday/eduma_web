import 'package:eduma_web/features/notifications/data/notifications_models.dart';
import 'package:test/test.dart';

void main() {
  group('NotificationsFeedLogic', () {
    test('parsePage extracts invite payload and unread count', () {
      final result = NotificationsFeedLogic.parsePage(
        {
          'unreadCount': 2,
          'notifications': [
            {
              '_id': 'n-1',
              'type': 'space_invite',
              'title': 'Space invitation',
              'body': 'Ada invited you to BIO 101',
              'isRead': false,
              'data': {
                'inviteId': 'inv-42',
                'spaceId': 'sp-9',
              },
            },
          ],
          'pagination': {'page': 1, 'totalPages': 1},
        },
        limit: 25,
      );

      expect(result.unreadCount, 2);
      expect(result.hasMore, isFalse);
      expect(result.items.length, 1);
      final item = result.items.first;
      expect(item.isInvite, isTrue);
      expect(item.inviteId, 'inv-42');
      expect(item.spaceId, 'sp-9');
    });
  });
}
