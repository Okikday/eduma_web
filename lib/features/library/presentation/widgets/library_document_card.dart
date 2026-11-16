import 'dart:js_interop';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:web/web.dart' as web;

import '../../../../core/presentation/eduma_icons.dart';
import '../../../auth/data/auth_api.dart';
import '../../data/library_models.dart';

/// Library document card supporting `.tall`, `.normal`, and `.wide` styles
/// matching `LibraryDocumentCard` + `LibraryDocumentWideCard` + `LibraryBookStage`
/// in `../eduma` (no `⋯` button on cards; bottom-right dark glass `'N pages'`
/// pill & gold lock circle on portrait covers, `'PDF'` glass tab on wide covers).
Component libraryDocumentCard(
  LibraryDocument doc, {
  LibraryCardStyle style = .normal,
  required VoidCallback onOpen,
}) {
  if (style == .wide) {
    return _wideCard(doc, onOpen: onOpen);
  }
  return _portraitCard(doc, showEdges: style == .tall, onOpen: onOpen);
}

Component _portraitCard(
  LibraryDocument doc, {
  required bool showEdges,
  required VoidCallback onOpen,
}) {
  final fileUrl = doc.resolvedFileUrl(edumaApiBaseUrl);
  final thumbUrl = doc.resolvedThumbnailUrl(edumaApiBaseUrl);
  final tints = LibraryCatalogLogic.bookTintsFor(doc);
  final authorLabel = doc.author.isNotEmpty ? doc.author : 'Unknown author';
  final edgeLayers = !showEdges
      ? 0
      : switch (doc.pageCount) {
          final pages? when pages >= 400 => 3,
          final pages? when pages >= 120 => 2,
          _ => 1,
        };

  return a(
    href: fileUrl,
    target: Target.blank,
    classes: 'eduma-library__card',
    attributes: {
      'rel': 'noopener noreferrer',
      'style': '--book-main: ${tints.main}; --book-end: ${tints.end};',
    },
    events: {
      'click': (event) {
        event.preventDefault();
        onOpen();
      },
    },
    [
      div(classes: 'eduma-library__stage', [
        if (doc.category.isNotEmpty) span(classes: 'eduma-library__stage-label', [.text(doc.category)]),
        if (doc.isVerified)
          span(
            classes: 'eduma-library__verified',
            attributes: {'title': 'Verified source'},
            [edumaIcon(EdumaIcons.verify, size: 16)],
          ),
        div(classes: 'eduma-library__book-wrap', [
          div(classes: 'eduma-library__book-stack eduma-library__book-stack--$edgeLayers', [
            for (var i = edgeLayers; i >= 1; i--)
              span(
                classes: 'eduma-library__page-edge eduma-library__page-edge--$i',
                attributes: {'aria-hidden': 'true'},
                [],
              ),
            div(classes: 'eduma-library__book', [
              _bookCoverFallback(tints.main),
              img(
                src: thumbUrl,
                alt: '',
                attributes: {
                  'loading': 'lazy',
                  'aria-hidden': 'true',
                  'draggable': 'false',
                },
                events: {
                  'error': (event) {
                    final target = event.currentTarget;
                    if (target != null && target.isA<web.HTMLElement>()) {
                      (target as web.HTMLElement).style.display = 'none';
                    }
                  },
                },
              ),
              span(classes: 'eduma-library__spine', attributes: {'aria-hidden': 'true'}, []),
              if (doc.isLocked || (doc.pageCount != null && doc.pageCount! > 0))
                div(classes: 'eduma-library__cover-footer', [
                  if (doc.isLocked)
                    span(
                      classes: 'eduma-library__gold-chip',
                      attributes: {'title': 'Premium · locked', 'aria-label': 'Premium locked'},
                      [edumaIcon(EdumaIcons.lockFilled, size: 11)],
                    ),
                  if (doc.pageCount case final pages? when pages > 0)
                    span(classes: 'eduma-library__pages', [.text('$pages pages')]),
                ]),
            ]),
          ]),
        ]),
      ]),
      span(classes: 'eduma-library__divider', attributes: {'aria-hidden': 'true'}, []),
      div(classes: 'eduma-library__caption', [
        h3([.text(doc.title)]),
        p(
          classes: doc.author.isNotEmpty ? 'eduma-library__author' : 'eduma-library__author is-muted',
          [.text(authorLabel)],
        ),
      ]),
    ],
  );
}

Component _wideCard(
  LibraryDocument doc, {
  required VoidCallback onOpen,
}) {
  final fileUrl = doc.resolvedFileUrl(edumaApiBaseUrl);
  final thumbUrl = doc.resolvedThumbnailUrl(edumaApiBaseUrl);
  final tints = LibraryCatalogLogic.bookTintsFor(doc);
  final authorLabel = doc.author.isNotEmpty ? doc.author : 'Unknown author';
  final metaParts = <String>[
    if (doc.pageCount case final pages? when pages > 0) '$pages pages',
    if (doc.formattedSize.isNotEmpty) doc.formattedSize,
  ];
  final footerLabel = metaParts.isEmpty ? 'Not started' : metaParts.join(' · ');

  return a(
    href: fileUrl,
    target: Target.blank,
    classes: 'eduma-library__wide-card',
    attributes: {
      'rel': 'noopener noreferrer',
      'style': '--book-main: ${tints.main}; --book-end: ${tints.end};',
    },
    events: {
      'click': (event) {
        event.preventDefault();
        onOpen();
      },
    },
    [
      div(classes: 'eduma-library__wide-cover', [
        _bookCoverFallback(tints.main),
        img(
          src: thumbUrl,
          alt: '',
          attributes: {
            'loading': 'lazy',
            'aria-hidden': 'true',
            'draggable': 'false',
          },
          events: {
            'error': (event) {
              final target = event.currentTarget;
              if (target != null && target.isA<web.HTMLElement>()) {
                (target as web.HTMLElement).style.display = 'none';
              }
            },
          },
        ),
        if (doc.isVerified)
          span(
            classes: 'eduma-library__wide-verified',
            attributes: {'title': 'Verified source'},
            [edumaIcon(EdumaIcons.verify, size: 15)],
          ),
        span(classes: 'eduma-library__format-tab', [.text(doc.formatLabel)]),
        if (doc.isLocked)
          span(
            classes: 'eduma-library__gold-chip eduma-library__gold-chip--wide',
            attributes: {'title': 'Premium · locked'},
            [edumaIcon(EdumaIcons.lockFilled, size: 11)],
          ),
      ]),
      span(classes: 'eduma-library__wide-divider', attributes: {'aria-hidden': 'true'}, []),
      div(classes: 'eduma-library__wide-details', [
        div(classes: 'eduma-library__wide-top', [
          if (doc.category.isNotEmpty)
            span(classes: 'eduma-library__stage-label eduma-library__stage-label--inline', [
              .text(doc.category),
            ]),
          h3([.text(doc.title)]),
          p(
            classes: doc.author.isNotEmpty ? 'eduma-library__author' : 'eduma-library__author is-muted',
            [.text(authorLabel)],
          ),
        ]),
        span(classes: 'eduma-library__wide-footer', [.text(footerLabel)]),
      ]),
    ],
  );
}

var _libraryCoverFilterSequence = 0;

Component _bookCoverFallback(String tint) {
  final filterId = 'eduma-library-mark-${_libraryCoverFilterSequence++}';
  return div(
    classes: 'eduma-library__fallback',
    attributes: {
      'style': '--eduma-fallback-tint: $tint;',
      'aria-hidden': 'true',
    },
    [
      svg(
        classes: 'eduma-library__filter-defs',
        attributes: {'aria-hidden': 'true', 'width': '0', 'height': '0'},
        [
          Component.element(
            tag: 'defs',
            children: [
              Component.element(
                tag: 'filter',
                attributes: {'id': filterId},
                children: [
                  Component.element(
                    tag: 'feColorMatrix',
                    attributes: {
                      'type': 'matrix',
                      'color-interpolation-filters': 'sRGB',
                      'values': _logoTintMatrix(tint),
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      img(
        src: 'assets/logo/logo.png',
        alt: '',
        classes: 'eduma-library__fallback-logo',
        attributes: {'style': 'filter: url(#$filterId);', 'draggable': 'false'},
      ),
    ],
  );
}

String _logoTintMatrix(String tint) {
  final color = switch (tint) {
    'var(--eduma-accent-violet)' => '#7c3aed',
    'var(--eduma-accent-sky)' => '#0284c7',
    'var(--eduma-accent-teal)' => '#0f9488',
    'var(--eduma-accent-amber)' => '#d97706',
    'var(--eduma-accent-rose)' => '#e11d48',
    'var(--eduma-accent-green)' => '#16a34a',
    _ => '#4b24d2',
  };
  final red = int.parse(color.substring(1, 3), radix: 16) / 255;
  final green = int.parse(color.substring(3, 5), radix: 16) / 255;
  final blue = int.parse(color.substring(5, 7), radix: 16) / 255;

  List<double> row(double channel) {
    final lift = (1 - channel) * 0.55;
    return [lift * 0.2126, lift * 0.7152, lift * 0.0722, 0, channel * 255];
  }

  return [
    ...row(red),
    ...row(green),
    ...row(blue),
    0,
    0,
    0,
    1,
    0,
  ].map((value) => value.toStringAsFixed(5)).join(' ');
}
