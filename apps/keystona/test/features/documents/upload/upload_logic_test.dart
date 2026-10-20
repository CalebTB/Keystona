import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keystona/features/documents/models/document_ocr.dart';
import 'package:keystona/features/documents/models/document_scan.dart';
import 'package:keystona/features/documents/models/document_upload_state.dart';
import 'package:keystona/features/documents/providers/document_categories_provider.dart';
import 'package:keystona/features/documents/providers/document_upload_provider.dart';
import 'package:keystona/features/documents/providers/scan_reading_provider.dart';
import 'package:keystona/features/documents/services/scan_pdf_composer.dart';
import 'package:keystona/features/documents/widgets/upload/upload_formatters.dart';
import 'package:keystona/features/subscription/providers/subscription_provider.dart';

import 'upload_test_support.dart';

ProviderContainer _container({
  bool premium = false,
  FakeUploadRepository? repo,
  FakeOcr? ocr,
}) {
  final c = ProviderContainer(
    overrides: uploadOverrides(premium: premium, repo: repo, ocr: ocr),
  );
  addTearDown(c.dispose);
  return c;
}

void _pick(DocumentUploadNotifier n) => n.setPickedFile(
  file: File('/nonexistent/furnace.pdf'),
  mimeType: 'application/pdf',
  sizeBytes: 1400000,
  name: 'furnace',
);

void main() {
  group('UploadFormatters', () {
    test('file meta, sizes and types', () {
      expect(
        UploadFormatters.fileMeta('application/pdf', 1468006),
        'PDF · 1.4 MB · JUST NOW',
      );
      expect(UploadFormatters.sizeLabel(320 * 1024), '320 KB');
      expect(UploadFormatters.typeLabel('image/heic'), 'HEIC');
      expect(UploadFormatters.typeLabel(null), 'JPG');
    });

    test('date field and reminder line follow the kit', () {
      final date = DateTime(2031, 3, 15);
      expect(UploadFormatters.fieldDate(date), '03/15/2031');
      expect(
        UploadFormatters.dateHelp(date, foundOnPage: 1),
        'Reminder on Feb 13, 2031 · Found on page 1',
      );
      expect(UploadFormatters.dateHelp(date), 'Reminder on Feb 13, 2031');
      expect(UploadFormatters.dateHelp(null), 'Pick the date it ends');
    });

    test('doc counts and scan headline', () {
      expect(UploadFormatters.docCount(0), 'EMPTY');
      expect(UploadFormatters.docCount(1), '1 DOC');
      expect(UploadFormatters.docCount(14), '14 DOCS');
      expect(UploadFormatters.scanHeadline(4), 'Smart scan read 4 details.');
      expect(UploadFormatters.scanHeadline(1), 'Smart scan read 1 detail.');
    });
  });

  group('ScanPdfComposer', () {
    test('writes a PDF with one page per image and a valid xref', () {
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);
      final bytes = ScanPdfComposer.compose([
        ScanPdfPage(jpegBytes: jpeg, width: 100, height: 200),
        ScanPdfPage(jpegBytes: jpeg, width: 100, height: 100),
      ]);
      final text = latin1.decode(bytes);
      expect(text.startsWith('%PDF-1.4'), isTrue);
      expect(text, contains('/Count 2'));
      expect(text, contains('/Type /Page '));
      expect(text.trimRight().endsWith('%%EOF'), isTrue);
      // startxref points at the xref table.
      final at = int.parse(
        RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!,
      );
      expect(text.substring(at).startsWith('xref'), isTrue);
    });
  });

  group('state rules', () {
    test('expires defaults on for warranty-like categories only', () {
      const base = DocumentUploadState();
      expect(base.copyWith(categoryName: 'Warranty').expires, isTrue);
      expect(base.copyWith(categoryName: 'Receipt').expires, isFalse);
      expect(
        base.copyWith(categoryName: 'Warranty', expiresChoice: false).expires,
        isFalse,
      );
    });

    test(
      'Save needs a file, a name, a category and a date when it expires',
      () {
        var s = DocumentUploadState(
          file: File('/x.pdf'),
          name: 'A',
          categoryId: 'c',
          categoryName: 'Receipt',
        );
        expect(s.canSave, isTrue);
        s = s.copyWith(name: '  ');
        expect(s.canSave, isFalse);
        s = s.copyWith(name: 'A', categoryName: 'Warranty');
        expect(s.canSave, isFalse, reason: 'expires but no date');
        s = s.copyWith(expirationDate: DateTime(2031));
        expect(s.canSave, isTrue);
      },
    );

    test('reading percent: quarter per stage plus a head start', () {
      expect(const ScanReadingState().percent, 12);
      expect(
        const ScanReadingState(
          status: ScanReadingStatus.reading,
          completed: 2,
        ).percent,
        62,
      );
      expect(
        const ScanReadingState(
          status: ScanReadingStatus.done,
          completed: 4,
        ).percent,
        100,
      );
    });

    test('scan outcome label', () {
      ScanOutcome o(int pages, bool smart) => ScanOutcome(
        file: File('/x'),
        mimeType: 'image/jpeg',
        sizeBytes: 1,
        pageCount: pages,
        previewFile: File('/x'),
        smart: smart,
      );
      expect(o(3, true).label, 'Scan · 3 pages');
      expect(o(1, true).label, 'Scan · 1 page');
      expect(o(1, false).label, 'Photo');
    });
  });

  group('DocumentUploadNotifier', () {
    test('picking a file pre-fills the name and removing it resets', () {
      final c = _container();
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      expect(c.read(documentUploadProvider).name, 'furnace');
      expect(c.read(documentUploadProvider).hasFile, isTrue);
      n.removeFile();
      expect(c.read(documentUploadProvider).hasFile, isFalse);
    });

    test('default category is Other, falling back to the first', () {
      final c = _container();
      final n = c.read(documentUploadProvider.notifier);
      n.useDefaultCategory(kCategories);
      expect(c.read(documentUploadProvider).categoryName, 'Other');
      n.selectCategory(kCategories.first);
      n.useDefaultCategory(kCategories);
      expect(c.read(documentUploadProvider).categoryName, 'Warranty');
    });

    test('tags: trims, ignores repeats, caps length and count', () {
      final c = _container();
      final n = c.read(documentUploadProvider.notifier);
      expect(n.addTag('  furnace,'), isTrue);
      expect(n.addTag('FURNACE'), isFalse);
      expect(n.addTag('   '), isFalse);
      expect(n.addTag('x' * 31), isFalse);
      for (var i = 0; i < 7; i++) {
        expect(n.addTag('tag $i'), isTrue);
      }
      expect(c.read(documentUploadProvider).tags.length, 8);
      expect(n.addTag('one too many'), isFalse);
      n.removeTag('furnace');
      expect(c.read(documentUploadProvider).tags, isNot(contains('furnace')));
    });

    test('smart scan result fills the form and marks the fields', () async {
      final c = _container();
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      await c.read(documentCategoriesProvider.future);
      await n.applyScanResult(fullResult());
      final s = c.read(documentUploadProvider);
      expect(s.name, 'Northline furnace warranty');
      expect(s.categoryName, 'Warranty');
      expect(s.expirationDate, DateTime(2031, 3, 15));
      expect(s.expires, isTrue);
      expect(s.link?.name, 'Furnace');
      expect(s.link?.detail, 'Matched model NF95-080B');
      expect(s.scanFilled, UploadField.values.toSet());
      expect(s.scanDetailCount, 4);
    });

    test(
      'editing a field drops its mark and later results never overwrite it',
      () async {
        final c = _container();
        final n = c.read(documentUploadProvider.notifier);
        _pick(n);
        await c.read(documentCategoriesProvider.future);
        await n.applyScanResult(fullResult());
        n.setName('My own name');
        expect(
          c.read(documentUploadProvider).scanFilled,
          isNot(contains(UploadField.name)),
        );
        await n.applyScanResult(fullResult());
        expect(c.read(documentUploadProvider).name, 'My own name');
      },
    );

    test('background reading fills the form once it lands', () async {
      final ocr = FakeOcr();
      final c = _container(ocr: ocr);
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      c.read(scanReadingProvider.notifier).start([File('/x')]);
      ocr.emit(1, const OcrResult(textSummary: 'a'));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(documentUploadProvider).scanFilled, isEmpty);
      await c.read(documentCategoriesProvider.future);
      ocr.emit(4, fullResult());
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(c.read(documentUploadProvider).name, 'Northline furnace warranty');
    });

    test(
      'submit sends the request, with a date-only expiry and linked ids',
      () async {
        final repo = FakeUploadRepository();
        final c = _container(repo: repo);
        final n = c.read(documentUploadProvider.notifier);
        _pick(n);
        n.selectCategory(kCategories.first);
        n.setExpirationDate(DateTime(2031, 3, 15));
        n.setLink((
          id: 'app-1',
          isAppliance: true,
          name: 'Fridge',
          detail: null,
        ));
        n.addTag('fridge');
        n.setNotes('  in the drawer ');
        await n.submit();
        final s = c.read(documentUploadProvider);
        expect(s.phase, UploadPhase.success);
        expect(s.savedDocumentId, 'doc-1');
        expect(repo.last?.categoryId, 'c-warranty');
        expect(repo.last?.expirationDate, DateTime(2031, 3, 15));
        expect(repo.last?.linkedApplianceId, 'app-1');
        expect(repo.last?.linkedSystemId, isNull);
        expect(repo.last?.tags, ['fridge']);
        expect(repo.enforced, isTrue, reason: 'free plan enforces the limit');
      },
    );

    test('premium does not enforce the free limit', () async {
      final repo = FakeUploadRepository();
      final c = _container(premium: true, repo: repo);
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      n.selectCategory(kCategories[2]);
      await n.submit();
      expect(repo.enforced, isFalse);
    });

    test('submit does nothing while the form is not ready', () async {
      final repo = FakeUploadRepository();
      final c = _container(repo: repo);
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      await n.submit();
      expect(repo.calls, 0, reason: 'no category yet');
    });

    test('a failed save keeps the form and can be retried', () async {
      final repo = FakeUploadRepository()..error = Exception('offline');
      final c = _container(repo: repo);
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      n.selectCategory(kCategories[2]);
      await n.submit();
      var s = c.read(documentUploadProvider);
      expect(s.phase, UploadPhase.editing);
      expect(s.failure, UploadFailure.generic);
      expect(s.hasFile, isTrue);
      repo.error = null;
      n.clearFailure();
      await n.submit();
      s = c.read(documentUploadProvider);
      expect(s.phase, UploadPhase.success);
      expect(repo.calls, 2);
    });

    test('hitting the free limit is reported as such', () async {
      final repo = FakeUploadRepository()
        ..error = const DocumentLimitException();
      final c = _container(repo: repo);
      final n = c.read(documentUploadProvider.notifier);
      _pick(n);
      n.selectCategory(kCategories[2]);
      await n.submit();
      expect(
        c.read(documentUploadProvider).failure,
        UploadFailure.limitReached,
      );
    });
  });
}
