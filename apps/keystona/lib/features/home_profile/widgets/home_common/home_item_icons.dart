import 'package:flutter/material.dart';

/// Icon for a system or appliance category (the database values).
abstract final class HomeItemIcons {
  static IconData forCategory(String category) => switch (category) {
    'hvac' => Icons.thermostat_outlined,
    'plumbing' => Icons.water_drop_outlined,
    'electrical' => Icons.electrical_services_outlined,
    'roofing' => Icons.roofing_outlined,
    'foundation' => Icons.foundation_outlined,
    'siding' => Icons.home_outlined,
    'windows_doors' => Icons.door_front_door_outlined,
    'insulation' => Icons.waves_outlined,
    'garage' => Icons.garage_outlined,
    'kitchen' => Icons.kitchen_outlined,
    'laundry' => Icons.local_laundry_service_outlined,
    'climate' => Icons.ac_unit,
    'cleaning' => Icons.cleaning_services_outlined,
    'outdoor' => Icons.yard_outlined,
    'bathroom' => Icons.bathtub_outlined,
    _ => Icons.build_outlined,
  };
}
