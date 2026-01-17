import 'package:flutter/material.dart';

// System Type Enum (enhanced with icons and display names)
enum SystemType {
  hvac('HVAC', Icons.hvac),
  waterHeater('Water Heater', Icons.water_drop),
  roof('Roof', Icons.roofing),
  electrical('Electrical Panel', Icons.electrical_services_outlined),
  plumbing('Plumbing', Icons.plumbing),
  foundation('Foundation', Icons.foundation);

  const SystemType(this.displayName, this.icon);
  final String displayName;
  final IconData icon;

  String toDbValue() {
    switch (this) {
      case SystemType.hvac:
        return 'hvac';
      case SystemType.waterHeater:
        return 'water_heater';
      case SystemType.roof:
        return 'roof';
      case SystemType.electrical:
        return 'electrical';
      case SystemType.plumbing:
        return 'plumbing';
      case SystemType.foundation:
        return 'foundation';
    }
  }

  static SystemType fromString(String value) {
    switch (value) {
      case 'hvac':
        return SystemType.hvac;
      case 'water_heater':
        return SystemType.waterHeater;
      case 'roof':
        return SystemType.roof;
      case 'electrical':
        return SystemType.electrical;
      case 'plumbing':
        return SystemType.plumbing;
      case 'foundation':
        return SystemType.foundation;
      default:
        throw ArgumentError('Unknown system_type: $value');
    }
  }
}

// System Condition Enum (enhanced with colors and icons)
enum SystemCondition {
  excellent('Excellent', Color(0xFF4CAF50), Icons.check_circle),
  good('Good', Color(0xFF8BC34A), Icons.check_circle_outline),
  fair('Fair', Color(0xFFFF9800), Icons.warning),
  poor('Poor', Color(0xFFF44336), Icons.error);

  const SystemCondition(this.displayName, this.color, this.icon);
  final String displayName;
  final Color color;
  final IconData icon;

  String toDbValue() {
    switch (this) {
      case SystemCondition.excellent:
        return 'excellent';
      case SystemCondition.good:
        return 'good';
      case SystemCondition.fair:
        return 'fair';
      case SystemCondition.poor:
        return 'poor';
    }
  }

  static SystemCondition? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'excellent':
        return SystemCondition.excellent;
      case 'good':
        return SystemCondition.good;
      case 'fair':
        return SystemCondition.fair;
      case 'poor':
        return SystemCondition.poor;
      default:
        return null;
    }
  }
}

// Main HomeSystem model
class HomeSystem {
  final String id;
  final String propertyId;
  final String name;
  final SystemType systemType;
  final String? systemSubtype; // Free-form text
  final String? manufacturer;
  final String? modelNumber;
  final DateTime? installationDate;
  final SystemCondition? condition;
  final String? conditionNotes;
  final String? photoUrl; // Signed URL
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeSystem({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.systemType,
    this.systemSubtype,
    this.manufacturer,
    this.modelNumber,
    this.installationDate,
    this.condition,
    this.conditionNotes,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeSystem.fromJson(Map<String, dynamic> json) {
    return HomeSystem(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      name: json['name'] as String,
      systemType: SystemType.fromString(json['system_type'] as String),
      systemSubtype: json['system_subtype'] as String?,
      manufacturer: json['manufacturer'] as String?,
      modelNumber: json['model_number'] as String?,
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'] as String)
          : null,
      condition: SystemCondition.fromString(json['condition'] as String?),
      conditionNotes: json['condition_notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'name': name,
      'system_type': systemType.toDbValue(),
      'system_subtype': systemSubtype,
      'manufacturer': manufacturer,
      'model_number': modelNumber,
      'installation_date':
          installationDate?.toIso8601String().split('T')[0],
      'condition': condition?.toDbValue(),
      'condition_notes': conditionNotes,
      'photo_url': photoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  HomeSystem copyWith({
    String? id,
    String? propertyId,
    String? name,
    SystemType? systemType,
    String? systemSubtype,
    String? manufacturer,
    String? modelNumber,
    DateTime? installationDate,
    SystemCondition? condition,
    String? conditionNotes,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeSystem(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      name: name ?? this.name,
      systemType: systemType ?? this.systemType,
      systemSubtype: systemSubtype ?? this.systemSubtype,
      manufacturer: manufacturer ?? this.manufacturer,
      modelNumber: modelNumber ?? this.modelNumber,
      installationDate: installationDate ?? this.installationDate,
      condition: condition ?? this.condition,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
