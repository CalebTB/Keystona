import 'docs_expiry.dart';

/// A document that has an end date, for the Expiring screen.
class ExpiringDocument {
  const ExpiringDocument({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categoryIcon,
    required this.expirationDate,
    this.provider,
  });

  final String id;
  final String name;
  final String categoryName;

  /// Category icon key, resolved with `CategoryIcons.forKey`.
  final String categoryIcon;
  final DateTime expirationDate;

  /// Issuer or provider name from the document's metadata, when known.
  final String? provider;

  DocsExpiry expiry([DateTime? now]) => DocsExpiry.of(expirationDate, now: now);

  /// "INSURANCE · STATEWIDE MUTUAL" — category, then provider when known.
  String get subtitle {
    final base = categoryName.toUpperCase();
    final p = provider;
    return (p == null || p.isEmpty) ? base : '$base · ${p.toUpperCase()}';
  }
}
