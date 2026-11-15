import 'package:eduma_web/features/library/data/library_models.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryCatalogLogic', () {
    test('parseDocumentsPage extracts metadata and pagination', () {
      final page = LibraryCatalogLogic.parseDocumentsPage(
        {
          'documents': [
            {
              '_id': 'doc-1',
              'title': 'Linear Algebra Done Right',
              'author': 'Sheldon Axler',
              'category': 'Mathematics',
              'pageCount': 340,
              'sizeBytes': 2621440,
              'isVerified': true,
              'courseCodes': ['MTH201'],
            },
          ],
          'pagination': {'page': 1, 'totalPages': 3},
        },
        limit: 24,
      );

      expect(page.documents.length, 1);
      final doc = page.documents.first;
      expect(doc.title, 'Linear Algebra Done Right');
      expect(doc.formattedSize, '2.5 MB');
      expect(doc.isVerified, isTrue);
      expect(
        doc.resolvedFileUrl('https://api.example.com'),
        'https://api.example.com/library/documents/doc-1/file.pdf',
      );
      expect(page.hasMore, isTrue);
    });

    test('bookTintsFor deterministically resolves category tints', () {
      final mathDocA = LibraryDocument.fromMap({
        '_id': 'd1',
        'title': 'Calculus',
        'category': 'Mathematics',
      });
      final mathDocB = LibraryDocument.fromMap({
        '_id': 'd2',
        'title': 'Topology',
        'category': ' mathematics ',
      });

      final tintsA = LibraryCatalogLogic.bookTintsFor(mathDocA);
      final tintsB = LibraryCatalogLogic.bookTintsFor(mathDocB);
      expect(tintsA, equals(tintsB));
      expect(tintsA.main, startsWith('var(--eduma-accent-'));
      expect(tintsA.end, isNot(equals(tintsA.main)));
    });
  });
}
