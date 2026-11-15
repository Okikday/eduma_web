import 'package:eduma_web/features/main/data/main_preference_codec.dart';
import 'package:eduma_web/features/main/data/main_space.dart';
import 'package:test/test.dart';

void main() {
  group('MainPreferenceCodec', () {
    test('parses and serializes Flutter-compatible space card style values', () {
      expect(MainPreferenceCodec.parseSpaceGridView('grid'), isTrue);
      expect(MainPreferenceCodec.parseSpaceGridView('list'), isFalse);
      expect(MainPreferenceCodec.parseSpaceGridView(null), isFalse);
      expect(MainPreferenceCodec.serializeSpaceGridView(true), 'grid');
      expect(MainPreferenceCodec.serializeSpaceGridView(false), 'list');
    });

    test('parses and serializes Flutter-compatible space sort values', () {
      expect(MainPreferenceCodec.parseSpaceSort('name'), MainSpaceSort.name);
      expect(MainPreferenceCodec.parseSpaceSort('created'), MainSpaceSort.date);
      expect(MainPreferenceCodec.parseSpaceSort('date'), MainSpaceSort.date);
      expect(MainPreferenceCodec.parseSpaceSort('accessed'), MainSpaceSort.accessed);
      expect(MainPreferenceCodec.parseSpaceSort('unknown'), MainSpaceSort.recent);
      expect(MainPreferenceCodec.serializeSpaceSort(MainSpaceSort.date), 'created');
      expect(MainPreferenceCodec.serializeSpaceSort(MainSpaceSort.recent), 'recent');
    });
  });
}
