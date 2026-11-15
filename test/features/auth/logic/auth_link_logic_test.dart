import 'package:eduma_web/features/auth/logic/auth_link_logic.dart';
import 'package:test/test.dart';

void main() {
  group('AuthLinkLogic.tokenFrom', () {
    test('keeps a 6-digit verification/reset code or raw token intact', () {
      expect(AuthLinkLogic.tokenFrom('123456'), '123456');
      expect(AuthLinkLogic.tokenFrom('  tok_abc.123-xyz  '), 'tok_abc.123-xyz');
    });

    test('extracts token from pasted full https URL', () {
      expect(
        AuthLinkLogic.tokenFrom(
          'https://eduma.app/reset-password?token=abcDEF_123',
          expect: AuthLinkKind.resetPassword,
        ),
        'abcDEF_123',
      );
    });

    test('extracts token from hash URL, scheme URL, bare path, or query prefix', () {
      expect(
        AuthLinkLogic.tokenFrom('https://eduma.app/#/reset-password?token=hashTok9'),
        'hashTok9',
      );
      expect(
        AuthLinkLogic.tokenFrom('eduma://verify-email?token=deepTok1'),
        'deepTok1',
      );
      expect(
        AuthLinkLogic.tokenFrom('/reset-password?token=pathTok1'),
        'pathTok1',
      );
      expect(
        AuthLinkLogic.tokenFrom('?token=queryTok1&foo=bar'),
        'queryTok1',
      );
    });

    test('rejects links belonging to another auth action when expect is set', () {
      expect(
        AuthLinkLogic.tokenFrom(
          'https://eduma.app/verify-email?token=verifyTok123',
          expect: AuthLinkKind.resetPassword,
        ),
        isNull,
      );
      expect(
        AuthLinkLogic.tokenFrom(
          'https://eduma.app/reset-password?token=resetTok123',
          expect: AuthLinkKind.verifyEmail,
        ),
        isNull,
      );
    });

    test('rejects empty, whitespace-containing, or too-short inputs', () {
      expect(AuthLinkLogic.tokenFrom(''), isNull);
      expect(AuthLinkLogic.tokenFrom('12345'), isNull);
      expect(AuthLinkLogic.tokenFrom('token with spaces'), isNull);
    });
  });
}
