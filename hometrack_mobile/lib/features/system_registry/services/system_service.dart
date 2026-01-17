import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hometrack_mobile/core/errors/app_errors.dart';
import '../models/home_system.dart';
import '../models/system_result.dart';

class SystemService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<SystemResult<List<HomeSystem>>> getSystemsForProperty(
    String propertyId,
  ) async {
    try {
      final response = await _supabase
          .from('home_systems')
          .select()
          .eq('property_id', propertyId)
          .order('system_type');

      final systems = (response as List)
          .map((json) => HomeSystem.fromJson(json))
          .toList();

      return SystemSuccess(systems);
    } on PostgrestException catch (e) {
      return SystemFailure(_mapPostgrestException(e));
    } catch (e) {
      return SystemFailure(UnknownError(e.toString()));
    }
  }

  Future<SystemResult<HomeSystem>> getSystemById(String systemId) async {
    try {
      final response = await _supabase
          .from('home_systems')
          .select()
          .eq('id', systemId)
          .single();

      return SystemSuccess(HomeSystem.fromJson(response));
    } on PostgrestException catch (e) {
      return SystemFailure(_mapPostgrestException(e));
    } catch (e) {
      return SystemFailure(UnknownError(e.toString()));
    }
  }

  Future<SystemResult<HomeSystem>> createSystem(HomeSystem system) async {
    // Validate input
    final validationError = _validateSystem(system);
    if (validationError != null) {
      return SystemFailure(InvalidDataError(validationError));
    }

    try {
      final response = await _supabase
          .from('home_systems')
          .insert(system.toJson())
          .select()
          .single();

      return SystemSuccess(HomeSystem.fromJson(response));
    } on PostgrestException catch (e) {
      return SystemFailure(_mapPostgrestException(e));
    } catch (e) {
      return SystemFailure(UnknownError(e.toString()));
    }
  }

  Future<SystemResult<HomeSystem>> updateSystem(HomeSystem system) async {
    // Validate input
    final validationError = _validateSystem(system);
    if (validationError != null) {
      return SystemFailure(InvalidDataError(validationError));
    }

    try {
      final response = await _supabase
          .from('home_systems')
          .update(system.toJson())
          .eq('id', system.id)
          .select()
          .single();

      return SystemSuccess(HomeSystem.fromJson(response));
    } on PostgrestException catch (e) {
      return SystemFailure(_mapPostgrestException(e));
    } catch (e) {
      return SystemFailure(UnknownError(e.toString()));
    }
  }

  Future<SystemResult<void>> deleteSystem(String systemId) async {
    try {
      // Photo deletion handled by database trigger
      await _supabase.from('home_systems').delete().eq('id', systemId);

      return const SystemSuccess(null);
    } on PostgrestException catch (e) {
      return SystemFailure(_mapPostgrestException(e));
    } catch (e) {
      return SystemFailure(UnknownError(e.toString()));
    }
  }

  // Generate signed URL instead of public URL
  Future<SystemResult<String>> uploadSystemPhoto(
    String systemId,
    String filePath,
  ) async {
    try {
      // Validate file
      await _validatePhotoFile(filePath);

      // Compress image
      final compressedFile = await _compressImage(filePath);

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = filePath.split('.').last.toLowerCase();
      final fileName = 'photo-$timestamp.$extension';
      final path = '$systemId/$fileName';

      // Upload to storage
      await _supabase.storage.from('system-photos').upload(
            path,
            compressedFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // SECURITY FIX: Generate signed URL (expires in 1 hour)
      final signedUrl = await _supabase.storage
          .from('system-photos')
          .createSignedUrl(path, 3600);

      return SystemSuccess(signedUrl);
    } on StorageException {
      return const SystemFailure(PhotoUploadError());
    } catch (e) {
      return SystemFailure(UnknownError(e.toString()));
    }
  }

  // Compress image with improved settings (75% quality)
  Future<File> _compressImage(String filePath) async {
    final targetPath =
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      targetPath,
      quality: 75, // Reduced from 85% for better storage efficiency
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

  // Validate photo file
  Future<void> _validatePhotoFile(String filePath) async {
    final file = File(filePath);
    final size = await file.length();

    if (size > 50 * 1024 * 1024) {
      throw const InvalidDataError('Photo must be smaller than 50MB');
    }

    final extension = filePath.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'heic'].contains(extension)) {
      throw const InvalidDataError('Photo must be JPG, PNG, or HEIC');
    }
  }

  // Service-level validation
  String? _validateSystem(HomeSystem system) {
    if (system.name.trim().length < 3) {
      return 'System name must be at least 3 characters';
    }
    if (system.name.length > 255) {
      return 'System name must be less than 255 characters';
    }
    if (system.installationDate != null) {
      final now = DateTime.now();
      if (system.installationDate!.isAfter(now)) {
        return 'Installation date cannot be in the future';
      }
      if (system.installationDate!.year < 1950) {
        return 'Installation date seems too old. Please verify.';
      }
    }
    if (system.conditionNotes != null &&
        system.conditionNotes!.length > 2000) {
      return 'Condition notes must be less than 2000 characters';
    }
    return null;
  }

  // Map PostgrestException to user-friendly errors
  AppError _mapPostgrestException(PostgrestException e) {
    final code = e.code;
    final message = e.message.toLowerCase();

    // Check constraint violations
    if (code == '23514' || message.contains('check constraint')) {
      if (message.contains('system_type')) {
        return const InvalidDataError('Invalid system type selected');
      }
      if (message.contains('installation_date')) {
        return const InvalidDataError(
            'Installation date must be between 1950 and today');
      }
      if (message.contains('name')) {
        return const InvalidDataError(
            'System name must be 3-255 characters');
      }
      return InvalidDataError('Invalid data: ${e.message}');
    }

    // Foreign key violations
    if (code == '23503' || message.contains('foreign key')) {
      if (message.contains('property_id')) {
        return const InvalidDataError(
            'Property not found or access denied');
      }
      return const InvalidDataError('Referenced record not found');
    }

    // Not null violations
    if (code == '23502' || message.contains('not null')) {
      return const InvalidDataError('Required field is missing');
    }

    // Network errors
    if (message.contains('network') || message.contains('timeout')) {
      return const NetworkError();
    }

    return UnknownError(e.message);
  }
}
