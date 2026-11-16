import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/flutter_embedded_page.dart';

class AssistantChatPage extends StatelessComponent {
  const AssistantChatPage({super.key});

  @override
  Component build(BuildContext context) => flutterEmbeddedPage(
    title: 'New AI chat',
    route: '/assistantNewChat',
  );
}
