import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'features/ai/presentation/pages/assistant_chat_page.dart';
import 'features/ai/presentation/pages/assistant_history_page.dart';
import 'features/auth/presentation/pages/forgot_password.dart';
import 'features/auth/presentation/pages/sign_in.dart';
import 'features/auth/presentation/pages/sign_up.dart';
import 'features/auth/presentation/pages/verify_email.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';
import 'features/library/presentation/pages/library_page.dart';
import 'features/legal/presentation/pages/legal_document_page.dart';
import 'features/main/presentation/pages/main_home.dart';
import 'features/main/presentation/pages/recent_canvases_see_all_page.dart';
import 'features/main/presentation/pages/spaces_see_all_page.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/space/presentation/pages/space_detail_page.dart';
import 'features/space/presentation/pages/space_asset_preview_page.dart';
import 'features/space/presentation/pages/space_page_viewer_page.dart';
import 'features/streak/presentation/pages/streak_page.dart';

class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) => Router(
    routes: [
      Route(
        path: '/',
        title: 'Eduma Home',
        builder: (context, state) => MainHomePage(
          initialJoinCode: state.queryParams['join'] ?? '',
        ),
      ),
      Route(
        path: '/home',
        title: 'Eduma Home',
        builder: (context, state) => MainHomePage(
          initialJoinCode: state.queryParams['join'] ?? '',
        ),
      ),
      Route(
        path: '/sign-in',
        title: 'Sign in to Eduma',
        builder: (context, state) => SignInPage(email: state.queryParams['email'] ?? ''),
      ),
      Route(
        path: '/legalDocument',
        title: 'Legal documents — Eduma',
        builder: (context, state) => LegalDocumentPage(
          documentId: state.queryParams['id'] ?? 'terms',
        ),
      ),
      Route(
        path: '/sign-up',
        title: 'Create an Eduma account',
        builder: (context, state) => SignUpPage(
          referralCode: state.queryParams['ref'] ?? state.queryParams['referral'] ?? '',
        ),
      ),
      Route(
        path: '/forgot-password',
        title: 'Reset your Eduma password',
        builder: (context, state) => ForgotPasswordPage(
          email: state.queryParams['email'] ?? '',
          token: state.queryParams['token'] ?? '',
        ),
      ),
      Route(
        path: '/reset-password',
        title: 'Reset your Eduma password',
        builder: (context, state) => ForgotPasswordPage(
          email: state.queryParams['email'] ?? '',
          token: state.queryParams['token'] ?? '',
        ),
      ),
      Route(
        path: '/verify-email',
        title: 'Verify your Eduma email',
        builder: (context, state) => VerifyEmailPage(
          email: state.queryParams['email'] ?? '',
          token: state.queryParams['token'] ?? '',
          codeJustSent: state.queryParams['sent'] == 'true',
        ),
      ),
      Route(
        path: '/account',
        title: 'Eduma Home',
        builder: (context, state) => const MainHomePage(),
      ),
      Route(
        path: '/main',
        title: 'Eduma Home',
        builder: (context, state) => MainHomePage(
          initialJoinCode: state.queryParams['join'] ?? '',
        ),
      ),
      Route(
        path: '/join/:code',
        title: 'Join an Eduma Space',
        builder: (context, state) => MainHomePage(
          initialJoinCode: state.params['code'] ?? '',
        ),
      ),
      Route(
        path: '/spaceDetail',
        title: 'Eduma Space',
        builder: (context, state) => SpaceDetailPage(
          spaceId: state.queryParams['id'] ?? '',
        ),
      ),
      Route(
        path: '/spaces/:id',
        title: 'Eduma Space',
        builder: (context, state) => SpaceDetailPage(
          spaceId: state.params['id'] ?? '',
        ),
      ),
      Route(
        path: '/calendarTab',
        title: 'Eduma Calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      Route(
        path: '/calendar',
        title: 'Eduma Calendar',
        builder: (context, state) => const CalendarPage(),
      ),
      Route(
        path: '/libraryTab',
        title: 'Eduma Library',
        builder: (context, state) => const LibraryPage(),
      ),
      Route(
        path: '/library',
        title: 'Eduma Library',
        builder: (context, state) => const LibraryPage(),
      ),
      Route(
        path: '/notifications',
        title: 'Notifications — Eduma',
        builder: (context, state) => const NotificationsPage(),
      ),
      Route(
        path: '/profile',
        title: 'Profile & Settings — Eduma',
        builder: (context, state) => const ProfilePage(),
      ),
      Route(
        path: '/streak',
        title: 'Study Streak — Eduma',
        builder: (context, state) => const StreakPage(),
      ),
      Route(
        path: '/pinnedSpacesSeeAll',
        title: 'Pinned Spaces — Eduma',
        builder: (context, state) => const SpacesSeeAllPage(pinnedOnly: true),
      ),
      Route(
        path: '/recentSpacesSeeAll',
        title: 'All Spaces — Eduma',
        builder: (context, state) => const SpacesSeeAllPage(pinnedOnly: false),
      ),
      Route(
        path: '/recentCanvasesSeeAll',
        title: 'Recent Pages — Eduma',
        builder: (context, state) => const RecentCanvasesSeeAllPage(),
      ),
      Route(
        path: '/assistantHistory',
        title: 'AI Chats — Eduma',
        builder: (context, state) => AssistantHistoryPage(
          conversationId: state.queryParams['conversationId'],
        ),
      ),
      Route(
        path: '/assistantChat',
        title: 'New AI chat — Eduma',
        builder: (context, state) => const AssistantChatPage(),
      ),
      Route(
        path: '/spacePageStatic',
        title: 'Notes — Eduma',
        builder: (context, state) => SpacePageViewerPage(
          isDynamicCanvas: false,
          spaceId: state.queryParams['spaceId'],
          pageId: state.queryParams['id'],
        ),
      ),
      Route(
        path: '/filePreview',
        title: 'File preview — Eduma',
        builder: (context, state) => SpaceAssetPreviewPage(
          spaceId: state.queryParams['spaceId'] ?? '',
          assetId: state.queryParams['assetId'] ?? '',
        ),
      ),
      Route(
        path: '/spacePageCanvas',
        title: 'Canvas — Eduma',
        builder: (context, state) => SpacePageViewerPage(
          isDynamicCanvas: true,
          spaceId: state.queryParams['spaceId'],
          pageId: state.queryParams['id'],
        ),
      ),
    ],
  );
}
