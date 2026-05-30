import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'supabase_service.dart';

/// Result returned by the scan-label Edge Function.
class LabelScanResult {
  const LabelScanResult({
    this.brand,
    this.modelNumber,
    this.serialNumber,
    this.name,
    this.manufactureDate,
    this.estimatedYear,
  });

  factory LabelScanResult.fromJson(Map<String, dynamic> json) {
    return LabelScanResult(
      brand: json['brand'] as String?,
      modelNumber: json['modelNumber'] as String?,
      serialNumber: json['serialNumber'] as String?,
      name: json['name'] as String?,
      manufactureDate: json['manufactureDate'] as String?,
      estimatedYear: json['estimatedYear'] as int?,
    );
  }

  final String? brand;
  final String? modelNumber;
  final String? serialNumber;
  final String? name;
  final String? manufactureDate;
  final int? estimatedYear;

  bool get isEmpty =>
      brand == null &&
      modelNumber == null &&
      serialNumber == null &&
      name == null &&
      manufactureDate == null &&
      estimatedYear == null;

  int get fieldCount => [
        brand,
        modelNumber,
        serialNumber,
        name,
        manufactureDate ?? estimatedYear?.toString(),
      ].where((v) => v != null && v.isNotEmpty).length;
}

/// Sends a label photo to the scan-label Edge Function and returns
/// the extracted appliance/system data.
abstract final class LabelScannerService {
  static Future<LabelScanResult> scanImage(XFile photo) async {
    final session = SupabaseService.client.auth.currentSession;
    if (session == null) throw StateError('Not authenticated');

    final bytes = await photo.readAsBytes();
    final base64Image = base64Encode(bytes);

    final ext = photo.name.split('.').last.toLowerCase();
    final mimeType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final response = await SupabaseService.client.functions.invoke(
      'scan-label',
      body: {'imageBase64': base64Image, 'mimeType': mimeType},
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    if (response.data == null) {
      throw Exception('No response from scan-label function');
    }

    final data = response.data is Map
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);

    if (data.containsKey('error')) {
      throw Exception(data['error']);
    }

    return LabelScanResult.fromJson(data);
  }
}
