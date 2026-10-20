/// The few property facts the Systems screens need: which property, the
/// street line for the eyebrow, and the year built for suggestions.
class PropertyBrief {
  const PropertyBrief({required this.id, this.addressLine1, this.yearBuilt});

  final String id;
  final String? addressLine1;
  final int? yearBuilt;
}
