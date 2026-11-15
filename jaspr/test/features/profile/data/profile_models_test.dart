import 'package:eduma_web/features/profile/data/profile_models.dart';
import 'package:test/test.dart';

void main() {
  group('ProfileStats', () {
    test('formats hours and minutes cleanly', () {
      const stats = ProfileStats(notebooks: 4, spaces: 2, studySeconds: 5400);
      expect(stats.formattedStudyTime, '1h 30m');
    });
  });

  group('EditProfileLogic', () {
    test('allows saving name change without rechecking unchanged username', () {
      expect(
        EditProfileLogic.canSave(
          name: 'Ada Lovelace',
          currentName: 'Ada',
          username: 'ada_l',
          currentUsername: 'ada_l',
          usernameAvailable: null,
          isCheckingUsername: false,
        ),
        isTrue,
      );
    });

    test('requires username availability when username changed', () {
      expect(
        EditProfileLogic.canSave(
          name: 'Ada',
          currentName: 'Ada',
          username: '@ada.new',
          currentUsername: 'ada_l',
          usernameAvailable: null,
          isCheckingUsername: false,
        ),
        isFalse,
      );
      expect(
        EditProfileLogic.canSave(
          name: 'Ada',
          currentName: 'Ada',
          username: '@ada.new',
          currentUsername: 'ada_l',
          usernameAvailable: true,
          isCheckingUsername: false,
        ),
        isTrue,
      );
    });
  });

  group('ChangePasswordLogic', () {
    test('extracts token from pasted reset URL and validates length', () {
      expect(
        ChangePasswordLogic.tokenFrom('https://eduma.app/reset-password?token=tok123'),
        'tok123',
      );
      expect(
        ChangePasswordLogic.canSubmit(
          codeInput: 'tok123',
          password: 'password123',
          confirm: 'password123',
        ),
        isTrue,
      );
    });
  });
}
