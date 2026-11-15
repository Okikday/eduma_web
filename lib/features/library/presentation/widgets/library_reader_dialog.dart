import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../../core/presentation/eduma_icons.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/library_models.dart';

/// In-app PDF/document reader overlay for Library items.
Component libraryDocumentReaderModal({
  required LibraryDocument? document,
  required VoidCallback onClose,
}) {
  if (document == null) return div([]);
  final fileUrl = document.resolvedFileUrl(edumaApiBaseUrl);
  final authorLabel = document.author.isNotEmpty ? document.author : 'Library resource';
  final metaParts = [
    authorLabel,
    if (document.pageCount case final pages? when pages > 0) '$pages pages',
    if (document.formattedSize.isNotEmpty) document.formattedSize,
  ];

  return div(classes: 'eduma-modal-backdrop', [
    button(
      classes: 'eduma-modal-backdrop__scrim',
      type: ButtonType.button,
      attributes: {'aria-label': 'Close document reader'},
      onClick: onClose,
      [],
    ),
    section(
      classes: 'eduma-modal-sheet eduma-library-reader',
      attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': document.title},
      [
        div(classes: 'eduma-library-reader__head', [
          div(classes: 'eduma-library-reader__meta', [
            h2([.text(document.title)]),
            p([.text(metaParts.join(' · '))]),
          ]),
          div(classes: 'eduma-library-reader__actions', [
            a(
              href: fileUrl,
              target: Target.blank,
              classes: 'eduma-desktop-pill eduma-desktop-pill--outlined',
              attributes: {'rel': 'noopener noreferrer'},
              [
                edumaIcon(EdumaIcons.export3, size: 15),
                span([.text('Open tab')]),
              ],
            ),
            button(
              classes: 'eduma-modal-close',
              type: ButtonType.button,
              attributes: {'aria-label': 'Close reader'},
              onClick: onClose,
              [edumaIcon(EdumaIcons.closePlain, size: 18)],
            ),
          ]),
        ]),
        div(classes: 'eduma-library-reader__frame-wrap', [
          iframe(
            src: fileUrl,
            classes: 'eduma-library-reader__frame',
            attributes: {'title': document.title},
            [],
          ),
        ]),
      ],
    ),
  ]);
}
