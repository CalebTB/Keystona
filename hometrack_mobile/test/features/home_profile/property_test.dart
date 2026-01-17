import 'package:flutter_test/flutter_test.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/models/property_result.dart';

void main() {
  group('Property', () {
    test('fromJson creates correct model with all fields', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'address': '123 Main St',
        'city': 'San Francisco',
        'state': 'CA',
        'zip_code': '94102',
        'square_footage': 2000,
        'year_built': 2000,
        'bedrooms': 3,
        'bathrooms': 2.5,
        'lot_size': 0.25,
        'property_type': 'single_family',
        'climate_zone': null,
        'property_photo_url': 'https://example.com/photo.jpg',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final property = Property.fromJson(json);

      expect(property.id, 'test-id');
      expect(property.userId, 'user-123');
      expect(property.address, '123 Main St');
      expect(property.city, 'San Francisco');
      expect(property.state, 'CA');
      expect(property.zipCode, '94102');
      expect(property.squareFootage, 2000);
      expect(property.yearBuilt, 2000);
      expect(property.bedrooms, 3);
      expect(property.bathrooms, 2.5);
      expect(property.lotSize, 0.25);
      expect(property.propertyType, PropertyType.singleFamily);
      expect(property.climateZone, null);
      expect(property.propertyPhotoUrl, 'https://example.com/photo.jpg');
    });

    test('fromJson creates model with only required fields', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'address': '456 Oak Ave',
        'city': 'Los Angeles',
        'state': 'CA',
        'zip_code': '90001',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final property = Property.fromJson(json);

      expect(property.address, '456 Oak Ave');
      expect(property.city, 'Los Angeles');
      expect(property.state, 'CA');
      expect(property.zipCode, '90001');
      expect(property.squareFootage, null);
      expect(property.yearBuilt, null);
      expect(property.bedrooms, null);
      expect(property.bathrooms, null);
      expect(property.lotSize, null);
      expect(property.propertyType, null);
      expect(property.propertyPhotoUrl, null);
    });

    test('toJson converts model to correct JSON', () {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '789 Pine Rd',
        city: 'Portland',
        state: 'OR',
        zipCode: '97201',
        squareFootage: 1800,
        yearBuilt: 1995,
        bedrooms: 2,
        bathrooms: 2.0,
        lotSize: 0.15,
        propertyType: PropertyType.condo,
        climateZone: null,
        propertyPhotoUrl: null,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final json = property.toJson();

      expect(json['id'], 'test-id');
      expect(json['user_id'], 'user-123');
      expect(json['address'], '789 Pine Rd');
      expect(json['city'], 'Portland');
      expect(json['state'], 'OR');
      expect(json['zip_code'], '97201');
      expect(json['square_footage'], 1800);
      expect(json['year_built'], 1995);
      expect(json['bedrooms'], 2);
      expect(json['bathrooms'], 2.0);
      expect(json['lot_size'], 0.15);
      expect(json['property_type'], 'condo');
      expect(json['climate_zone'], null);
      expect(json['property_photo_url'], null);
    });

    test('copyWith creates new instance with updated fields', () {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '123 Main St',
        city: 'Seattle',
        state: 'WA',
        zipCode: '98101',
        squareFootage: 2000,
        yearBuilt: 2000,
        bedrooms: 3,
        bathrooms: 2.5,
        lotSize: 0.25,
        propertyType: PropertyType.singleFamily,
        climateZone: null,
        propertyPhotoUrl: null,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      final updated = property.copyWith(
        address: '456 New Address',
        squareFootage: 2500,
        propertyPhotoUrl: 'https://example.com/new-photo.jpg',
      );

      expect(updated.id, property.id);
      expect(updated.userId, property.userId);
      expect(updated.address, '456 New Address');
      expect(updated.city, property.city);
      expect(updated.squareFootage, 2500);
      expect(updated.propertyPhotoUrl, 'https://example.com/new-photo.jpg');
    });
  });

  group('PropertyType', () {
    test('toDbValue converts enum to database string', () {
      expect(PropertyType.singleFamily.toDbValue(), 'single_family');
      expect(PropertyType.condo.toDbValue(), 'condo');
      expect(PropertyType.townhouse.toDbValue(), 'townhouse');
      expect(PropertyType.multiFamily.toDbValue(), 'multi_family');
      expect(PropertyType.mobileHome.toDbValue(), 'mobile_home');
      expect(PropertyType.other.toDbValue(), 'other');
    });

    test('fromString converts database string to enum', () {
      expect(PropertyType.fromString('single_family'), PropertyType.singleFamily);
      expect(PropertyType.fromString('condo'), PropertyType.condo);
      expect(PropertyType.fromString('townhouse'), PropertyType.townhouse);
      expect(PropertyType.fromString('multi_family'), PropertyType.multiFamily);
      expect(PropertyType.fromString('mobile_home'), PropertyType.mobileHome);
      expect(PropertyType.fromString('other'), PropertyType.other);
    });

    test('fromString returns null for invalid value', () {
      expect(PropertyType.fromString('invalid'), null);
      expect(PropertyType.fromString(''), null);
      expect(PropertyType.fromString(null), null);
    });

    test('displayName provides human-readable names', () {
      expect(PropertyType.singleFamily.displayName, 'Single Family Home');
      expect(PropertyType.condo.displayName, 'Condominium');
      expect(PropertyType.townhouse.displayName, 'Townhouse');
      expect(PropertyType.multiFamily.displayName, 'Multi-Family');
      expect(PropertyType.mobileHome.displayName, 'Mobile Home');
      expect(PropertyType.other.displayName, 'Other');
    });
  });

  group('PropertyResult', () {
    test('PropertySuccess contains data', () {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '123 Main St',
        city: 'Boston',
        state: 'MA',
        zipCode: '02101',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = PropertySuccess<Property>(property);

      expect(result, isA<PropertySuccess>());
      expect(result.data, property);
    });

    test('PropertyFailure contains error', () {
      const result = PropertyFailure<Property>(NetworkError());

      expect(result, isA<PropertyFailure>());
      expect(result.error, isA<NetworkError>());
      expect(result.error.message, contains('internet'));
    });

    test('All error types have appropriate messages', () {
      const networkError = NetworkError();
      expect(networkError.message, contains('internet'));

      const photoError = PhotoUploadError();
      expect(photoError.message, contains('photo'));

      const invalidDataError = InvalidPropertyDataError();
      expect(invalidDataError.message, contains('Invalid'));

      const notFoundError = PropertyNotFoundError();
      expect(notFoundError.message, contains('not found'));

      const unauthorizedError = UnauthorizedError();
      expect(unauthorizedError.message, contains('Session'));

      const unknownError = UnknownError('Custom error');
      expect(unknownError.message, 'Custom error');
    });
  });
}
