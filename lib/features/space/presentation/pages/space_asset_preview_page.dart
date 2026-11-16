import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/data/eduma_memory_cache.dart';
import '../../../../core/presentation/desktop_scaffolds.dart';
import '../../../../core/presentation/eduma_link.dart';
import '../../../auth/data/auth_api.dart';
import '../../../main/data/main_space.dart';
import '../../data/space_detail_models.dart';
import '../../logic/space_detail_actions.dart';

class SpaceAssetPreviewPage extends StatefulComponent {
  const SpaceAssetPreviewPage({
    required this.spaceId,
    required this.assetId,
    super.key,
  });

  final String spaceId;
  final String assetId;

  @override
  State<SpaceAssetPreviewPage> createState() => _SpaceAssetPreviewPageState();
}

class _SpaceAssetPreviewPageState extends State<SpaceAssetPreviewPage> {
  SpaceAsset? _asset;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateComponent(covariant SpaceAssetPreviewPage oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.spaceId != component.spaceId || oldComponent.assetId != component.assetId) {
      _asset = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final spaceId = component.spaceId.trim();
    final assetId = component.assetId.trim();
    if (spaceId.isEmpty || assetId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'This preview link is missing its space or file id.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = SpaceDetailActions.currentSession ?? await SpaceDetailActions.restoreSession();
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _loading = false;
          _error = 'Sign in to view this file.';
        });
        return;
      }

      EdumaMemoryCache.instance.ensureUser(session.userId);
      var bundle = EdumaMemoryCache.instance.spaces[spaceId];
      if (bundle == null) {
        bundle = await SpaceDetailActions.loadSpace(session, spaceId);
        if (!mounted) return;
        EdumaMemoryCache.instance.spaces[spaceId] = bundle;
      }
      SpaceAsset? asset;
      for (final item in bundle.assets) {
        if (item.id == assetId) {
          asset = item;
          break;
        }
      }
      if (asset == null) {
        throw const MainApiException(
          'This file is no longer available in the space.',
        );
      }
      setState(() {
        _asset = asset;
        _loading = false;
      });
    } on AuthApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } on MainApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final asset = _asset;
    final title = asset?.displayName ?? 'File preview';
    final fallbackHref = '/spaceDetail?id=${Uri.encodeComponent(component.spaceId)}';
    return main_(
      classes: 'space-asset-preview',
      [
        pureAppBar(
          title: title,
          subtitle: asset?.fileName,
          fallbackHref: fallbackHref,
        ),
        div(classes: 'space-asset-preview__body', [
          if (_loading)
            div(
              classes: 'space-asset-preview__state',
              attributes: {'role': 'status', 'aria-live': 'polite'},
              [span(classes: 'main-home__spinner', [])],
            )
          else if (_error case final message?)
            div(
              classes: 'space-asset-preview__state space-asset-preview__state--error',
              attributes: {'role': 'alert'},
              [
                h2([.text('File unavailable')]),
                p([.text(message)]),
                edumaLink(
                  to: fallbackHref,
                  classes: 'space-asset-preview__back-link',
                  children: [.text('Back to space')],
                ),
              ],
            )
          else if (asset != null)
            _preview(asset),
        ]),
      ],
    );
  }

  Component _preview(SpaceAsset asset) {
    final uri = Uri.tryParse(asset.url.trim());
    if (uri == null || !uri.hasAuthority || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return div(
        classes: 'space-asset-preview__state space-asset-preview__state--error',
        attributes: {'role': 'alert'},
        [
          h2([.text('File unavailable')]),
          p([.text('This file does not have a valid web address.')]),
        ],
      );
    }

    final extension = asset.extension.toLowerCase();
    final driveFileId = _driveFileId(uri);
    final isImage = switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'avif' || 'bmp' => true,
      _ => false,
    };
    final previewUrl = driveFileId == null
        ? uri.toString()
        : isImage
        ? Uri.https('drive.google.com', '/thumbnail', {'id': driveFileId, 'sz': 'w1600'}).toString()
        : Uri.https('drive.google.com', '/file/d/$driveFileId/preview').toString();
    final openUrl = driveFileId == null
        ? uri.toString()
        : Uri.https('drive.google.com', '/file/d/$driveFileId/view').toString();

    final content = driveFileId != null
        ? isImage
              ? img(
                  src: previewUrl,
                  alt: asset.displayName,
                  classes: 'space-asset-preview__image',
                )
              : iframe(
                  src: previewUrl,
                  sandbox: 'allow-scripts allow-same-origin',
                  referrerPolicy: .noReferrer,
                  classes: 'space-asset-preview__document',
                  attributes: {'title': 'Preview of ${asset.displayName}'},
                  const [],
                )
        : switch (extension) {
            'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'avif' || 'bmp' => img(
              src: uri.toString(),
              alt: asset.displayName,
              classes: 'space-asset-preview__image',
            ),
            'pdf' => iframe(
              src: uri.toString(),
              sandbox: 'allow-same-origin',
              referrerPolicy: .noReferrer,
              classes: 'space-asset-preview__document',
              attributes: {'title': 'Preview of ${asset.displayName}'},
              const [],
            ),
            'mp3' || 'm4a' || 'aac' || 'ogg' || 'wav' || 'flac' => audio(
              src: uri.toString(),
              controls: true,
              preload: .metadata,
              classes: 'space-asset-preview__audio',
              const [],
            ),
            'mp4' || 'm4v' || 'webm' || 'mov' => video(
              src: uri.toString(),
              controls: true,
              preload: .metadata,
              classes: 'space-asset-preview__video',
              const [],
            ),
            _ => div(
              classes: 'space-asset-preview__state',
              [
                h2([.text('Preview not available for this file type')]),
                p([.text('Open the file in a new tab to view it.')]),
              ],
            ),
          };

    return div(classes: 'space-asset-preview__content', [
      div(classes: 'space-asset-preview__viewer', [content]),
      a(
        href: openUrl,
        target: Target.blank,
        attributes: {
          'rel': 'noopener noreferrer',
          'title': 'Open ${asset.displayName} in a new tab',
        },
        classes: 'space-asset-preview__open-link',
        [.text('Open in new tab')],
      ),
    ]);
  }
}

String? _driveFileId(Uri uri) {
  const driveHosts = {
    'drive.google.com',
    'drive.usercontent.google.com',
    'docs.google.com',
  };
  if (!driveHosts.contains(uri.host.toLowerCase())) return null;

  final queryId = uri.queryParameters['id'];
  if (queryId != null && queryId.isNotEmpty) return queryId;

  final segments = uri.pathSegments;
  final dIndex = segments.indexOf('d');
  if (dIndex >= 0 && dIndex + 1 < segments.length) return segments[dIndex + 1];
  return null;
}
