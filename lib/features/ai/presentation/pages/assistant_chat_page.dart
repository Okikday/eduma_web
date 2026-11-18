import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_link.dart';
import '../../../../core/presentation/flutter_embedded_page.dart';
import '../../../main/presentation/pages/main_home.dart';

/// `/assistantChat`: Home with a new AI chat open over it (the rail's AI
/// button opens the same chat over whichever screen is showing).
class AssistantChatPage extends StatefulComponent {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (!mounted) return;
      openAiChatOverlay(
        context,
        onClosed: () {
          if (mounted) edumaNavigate(context, '/main', replace: true);
        },
      );
    });
  }

  @override
  Component build(BuildContext context) => const MainHomePage();
}
