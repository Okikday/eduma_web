import 'dart:async';
import 'dart:convert';

import 'package:http/browser_client.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_rich_text.dart';
import '../../../auth/data/auth_api.dart';

class LegalDocumentPage extends StatefulComponent {
  const LegalDocumentPage({required this.documentId, super.key});

  final String documentId;

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  final BrowserClient _client = BrowserClient()..withCredentials = true;
  String? _markdown;
  String? _version;
  String? _notice;
  String? _error;
  bool _loading = true;

  String get _kind => component.documentId == 'privacy' ? 'privacy' : 'terms';
  String get _title => _kind == 'privacy' ? 'Privacy Policy' : 'Terms of Service';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateComponent(covariant LegalDocumentPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.documentId != component.documentId) unawaited(_load());
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
      _markdown = null;
      _version = null;
    });

    var fallbackNotice = '';
    if (_kind == 'terms') {
      try {
        final baseUrl = edumaApiBaseUrl.endsWith('/')
            ? edumaApiBaseUrl.substring(0, edumaApiBaseUrl.length - 1)
            : edumaApiBaseUrl;
        final response = await _client.get(Uri.parse('$baseUrl/legal/terms'));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw const FormatException('Terms endpoint returned an unsuccessful response.');
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw const FormatException('Terms endpoint returned an invalid document.');
        }
        final data = decoded['data'] is Map ? decoded['data'] as Map : decoded;
        final rawTerms = data['terms'] is Map ? data['terms'] as Map : data;
        final markdown = '${rawTerms['markdown'] ?? rawTerms['content'] ?? ''}';
        final version = '${rawTerms['version'] ?? ''}';
        if (markdown.trim().isEmpty || version.trim().isEmpty) {
          throw const FormatException('Terms endpoint returned an incomplete document.');
        }
        if (!mounted) return;
        setState(() {
          _markdown = markdown;
          _version = version;
          _loading = false;
        });
        return;
      } catch (_) {
        fallbackNotice = "The current Terms couldn't be loaded; showing the bundled copy.";
      }
    }

    try {
      final filename = _kind == 'privacy' ? 'privacy_policy.md' : 'terms_of_service.md';
      final response = await _client.get(Uri.base.resolve('/assets/legal/$filename'));
      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        throw const FormatException('Bundled legal document could not be loaded.');
      }
      if (!mounted) return;
      setState(() {
        _markdown = response.body;
        _version = 'bundled-draft';
        _notice = fallbackNotice.isEmpty ? null : fallbackNotice;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Couldn't load this document. Please try again later.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Component build(BuildContext context) => main_(classes: 'legal-document-page', [
    header(classes: 'legal-document__header', [
      a(
        href: '/sign-in',
        classes: 'legal-document__brand',
        attributes: {'aria-label': 'Eduma sign in'},
        [
          img(src: 'assets/logo/logo.png', alt: ''),
          strong([.text('Eduma')]),
        ],
      ),
      a(href: '/sign-in', classes: 'legal-document__back', [.text('Back to sign in')]),
    ]),
    article(classes: 'legal-document__content', [
      h1([.text(_title)]),
      if (_loading)
        p(
          classes: 'legal-document__state',
          attributes: {'role': 'status'},
          [
            .text('Loading document…'),
          ],
        )
      else if (_error case final message?)
        div(classes: 'legal-document__state', [
          p(attributes: {'role': 'alert'}, [.text(message)]),
          button(
            type: ButtonType.button,
            onClick: () => unawaited(_load()),
            [.text('Try again')],
          ),
        ])
      else ...[
        if (_notice case final notice?)
          p(
            classes: 'legal-document__notice',
            attributes: {'role': 'status'},
            [
              .text(notice),
            ],
          ),
        if (_version case final version?)
          p(classes: 'legal-document__version', [
            .text('Version: $version'),
          ]),
        ...edumaRenderMarkdownBlocks(_markdown ?? ''),
      ],
    ]),
  ]);
}
