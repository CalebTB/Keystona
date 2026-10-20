/// One row of an `ItemKeyValueCard`.
class ItemKeyValue {
  const ItemKeyValue({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  /// "BRAND", "SERIAL". Rendered uppercase.
  final String label;
  final String value;

  /// Shows a copy icon that copies [value] and reads "COPIED" for a moment.
  final bool copyable;
}
