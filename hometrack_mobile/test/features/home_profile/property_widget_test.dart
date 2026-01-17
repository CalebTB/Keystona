import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hometrack_mobile/features/home_profile/models/property.dart';
import 'package:hometrack_mobile/features/home_profile/widgets/property_card.dart';

void main() {
  group('PropertyCard Widget', () {
    testWidgets('displays property with all details', (WidgetTester tester) async {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '123 Main St',
        city: 'San Francisco',
        state: 'CA',
        zipCode: '94102',
        squareFootage: 2000,
        yearBuilt: 2000,
        bedrooms: 3,
        bathrooms: 2.5,
        lotSize: 0.25,
        propertyType: PropertyType.singleFamily,
        climateZone: null,
        propertyPhotoUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: property),
          ),
        ),
      );

      // Verify address is displayed
      expect(find.text('123 Main St'), findsOneWidget);

      // Verify city, state, zip is displayed
      expect(find.text('San Francisco, CA 94102'), findsOneWidget);

      // Verify optional details are displayed
      expect(find.text('3 bed'), findsOneWidget);
      expect(find.text('2.5 bath'), findsOneWidget);
      expect(find.text('2000 sq ft'), findsOneWidget);
    });

    testWidgets('displays property with only required fields', (WidgetTester tester) async {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '456 Oak Ave',
        city: 'Los Angeles',
        state: 'CA',
        zipCode: '90001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: property),
          ),
        ),
      );

      // Verify required fields are displayed
      expect(find.text('456 Oak Ave'), findsOneWidget);
      expect(find.text('Los Angeles, CA 90001'), findsOneWidget);

      // Verify optional details are not displayed
      expect(find.text('bed'), findsNothing);
      expect(find.text('bath'), findsNothing);
      expect(find.text('sq ft'), findsNothing);
    });

    testWidgets('shows photo placeholder when no photo URL', (WidgetTester tester) async {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '789 Pine Rd',
        city: 'Seattle',
        state: 'WA',
        zipCode: '98101',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(property: property),
          ),
        ),
      );

      // Verify placeholder icon is displayed
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (WidgetTester tester) async {
      final property = Property(
        id: 'test-id',
        userId: 'user-123',
        address: '321 Elm St',
        city: 'Portland',
        state: 'OR',
        zipCode: '97201',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PropertyCard(
              property: property,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(PropertyCard));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });
  });
}
