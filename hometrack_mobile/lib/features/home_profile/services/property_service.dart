import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hometrack_mobile/core/config/supabase_client.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/models/property_result.dart';

/// Service for property CRUD operations and photo uploads
///
/// Handles all property-related database operations and Supabase Storage
/// interactions. Follows auth service pattern for consistency.
class PropertyService {
  SupabaseClient get _client => supabase;

  /// Get all properties for the current user
  ///
  /// Returns PropertyResult with list of properties or error.
  /// Requires active user session.
  Future<PropertyResult<List<Property>>> getUserProperties() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const PropertyFailure(UnauthorizedError());
      }

      final response = await _client
          .from('properties')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final properties =
          (response as List).map((json) => Property.fromJson(json)).toList();

      return PropertySuccess(properties);
    } on PostgrestException catch (e) {
      return PropertyFailure(_mapPostgrestException(e));
    } catch (e) {
      return PropertyFailure(UnknownError(e.toString()));
    }
  }

  /// Get a single property by ID
  ///
  /// RLS ensures user can only access their own properties.
  Future<PropertyResult<Property>> getProperty(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const PropertyFailure(UnauthorizedError());
      }

      final response = await _client
          .from('properties')
          .select()
          .eq('id', id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        return const PropertyFailure(PropertyNotFoundError());
      }

      return PropertySuccess(Property.fromJson(response));
    } on PostgrestException catch (e) {
      return PropertyFailure(_mapPostgrestException(e));
    } catch (e) {
      return PropertyFailure(UnknownError(e.toString()));
    }
  }

  /// Create a new property
  ///
  /// Automatically sets user_id to current user and generates UUID.
  Future<PropertyResult<Property>> createProperty({
    required String address,
    required String city,
    required String state,
    required String zipCode,
    int? squareFootage,
    int? yearBuilt,
    int? bedrooms,
    double? bathrooms,
    double? lotSize,
    PropertyType? propertyType,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const PropertyFailure(UnauthorizedError());
      }

      final now = DateTime.now();
      final data = {
        'user_id': user.id,
        'address': address,
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'square_footage': squareFootage,
        'year_built': yearBuilt,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'lot_size': lotSize,
        'property_type': propertyType?.toDbValue(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response =
          await _client.from('properties').insert(data).select().single();

      return PropertySuccess(Property.fromJson(response));
    } on PostgrestException catch (e) {
      return PropertyFailure(_mapPostgrestException(e));
    } catch (e) {
      return PropertyFailure(UnknownError(e.toString()));
    }
  }

  /// Update an existing property
  ///
  /// RLS ensures user can only update their own properties.
  /// Updates the updated_at timestamp automatically via database trigger.
  Future<PropertyResult<Property>> updateProperty({
    required String id,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    int? squareFootage,
    int? yearBuilt,
    int? bedrooms,
    double? bathrooms,
    double? lotSize,
    PropertyType? propertyType,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const PropertyFailure(UnauthorizedError());
      }

      final data = <String, dynamic>{};
      if (address != null) data['address'] = address;
      if (city != null) data['city'] = city;
      if (state != null) data['state'] = state;
      if (zipCode != null) data['zip_code'] = zipCode;
      if (squareFootage != null) data['square_footage'] = squareFootage;
      if (yearBuilt != null) data['year_built'] = yearBuilt;
      if (bedrooms != null) data['bedrooms'] = bedrooms;
      if (bathrooms != null) data['bathrooms'] = bathrooms;
      if (lotSize != null) data['lot_size'] = lotSize;
      if (propertyType != null) data['property_type'] = propertyType.toDbValue();

      final response = await _client
          .from('properties')
          .update(data)
          .eq('id', id)
          .eq('user_id', user.id)
          .select()
          .single();

      return PropertySuccess(Property.fromJson(response));
    } on PostgrestException catch (e) {
      return PropertyFailure(_mapPostgrestException(e));
    } catch (e) {
      return PropertyFailure(UnknownError(e.toString()));
    }
  }

  /// Delete a property
  ///
  /// RLS ensures user can only delete their own properties.
  /// Also deletes associated photo from storage.
  Future<PropertyResult<void>> deleteProperty(String id) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const PropertyFailure(UnauthorizedError());
      }

      // Get property to check if it has a photo
      final propertyResult = await getProperty(id);
      if (propertyResult is PropertySuccess<Property>) {
        final property = propertyResult.data;
        if (property.propertyPhotoUrl != null) {
          // Delete photo from storage
          final photoPath = '${user.id}/$id/property-photo.jpg';
          await _client.storage.from('property-photos').remove([photoPath]);
        }
      }

      await _client
          .from('properties')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);

      return const PropertySuccess(null);
    } on PostgrestException catch (e) {
      return PropertyFailure(_mapPostgrestException(e));
    } on StorageException catch (_) {
      // Continue even if photo deletion fails - property deletion is more important
      return const PropertySuccess(null);
    } catch (e) {
      return PropertyFailure(UnknownError(e.toString()));
    }
  }

  /// Upload property photo with compression
  ///
  /// Compresses image to max 1920x1080 at quality 85 before upload.
  /// Uploads to: property-photos/{user_id}/{property_id}/property-photo.jpg
  Future<PropertyResult<String>> uploadPropertyPhoto({
    required String propertyId,
    required String filePath,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return const PropertyFailure(UnauthorizedError());
      }

      // Compress image
      final compressedFile = await _compressImage(filePath);

      // Upload to storage
      final storagePath = '${user.id}/$propertyId/property-photo.jpg';
      await _client.storage.from('property-photos').upload(
            storagePath,
            compressedFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Replace existing photo
            ),
          );

      // Get public URL with cache-busting parameter
      final baseUrl =
          _client.storage.from('property-photos').getPublicUrl(storagePath);
      final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update property record with photo URL
      await _client
          .from('properties')
          .update({'property_photo_url': publicUrl})
          .eq('id', propertyId)
          .eq('user_id', user.id);

      return PropertySuccess(publicUrl);
    } on StorageException catch (e) {
      return PropertyFailure(_mapStorageException(e));
    } on PostgrestException catch (e) {
      return PropertyFailure(_mapPostgrestException(e));
    } catch (e) {
      if (e.toString().contains('compress')) {
        return const PropertyFailure(PhotoUploadError());
      }
      return PropertyFailure(UnknownError(e.toString()));
    }
  }

  /// Compress image for upload
  ///
  /// Single-pass compression (no retry logic for MVP).
  /// Compresses to 85% quality in JPEG format which is adequate for property photos.
  Future<File> _compressImage(String filePath) async {
    final targetPath =
        '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      targetPath,
      quality: 85,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

  /// Map PostgrestException to user-friendly errors
  PropertyError _mapPostgrestException(PostgrestException e) {
    if (e.message.contains('violates check constraint')) {
      return const InvalidPropertyDataError();
    } else if (e.message.contains('not found')) {
      return const PropertyNotFoundError();
    } else {
      return UnknownError(e.message);
    }
  }

  /// Map StorageException to user-friendly errors
  PropertyError _mapStorageException(StorageException e) {
    if (e.message.contains('Payload too large')) {
      return const PhotoUploadError();
    } else {
      return UnknownError(e.message);
    }
  }
}
