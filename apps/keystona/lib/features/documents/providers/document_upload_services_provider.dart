import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/document_ocr_service.dart';
import '../services/document_scanner.dart';
import '../services/document_upload_repository.dart';
import '../services/image_picker_document_scanner.dart';
import '../services/scan_document_builder.dart';

part 'document_upload_services_provider.g.dart';

/// The camera behind the scan screen. Override in tests; swap for a scanner
/// that detects edges when one is available.
@Riverpod(keepAlive: true)
DocumentScanner documentScanner(Ref ref) => ImagePickerDocumentScanner();

/// Combines captured pages into the one file that gets stored.
@Riverpod(keepAlive: true)
ScanDocumentBuilder scanDocumentBuilder(Ref ref) => const ScanDocumentBuilder();

/// Reads scanned pages. Override in tests.
@Riverpod(keepAlive: true)
DocumentOcrService documentOcrService(Ref ref) =>
    const RemoteDocumentOcrService();

/// Stores a new document. Override in tests so nothing reaches Supabase.
@Riverpod(keepAlive: true)
DocumentUploadRepository documentUploadRepository(Ref ref) =>
    const SupabaseDocumentUploadRepository();

/// The address a user can forward documents to.
///
/// [#1.7a] Inbound email is not built yet; until it is this errors and the
/// "Or forward an email" card stays hidden.
@riverpod
Future<String> documentForwardingAddress(Ref ref) => throw UnimplementedError(
  'document forwarding address implemented by issue #1.7a',
);
