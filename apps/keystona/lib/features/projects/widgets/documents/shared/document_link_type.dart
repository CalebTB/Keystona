/// Document link type enum for the project documents feature.
///
/// Maps DB string values → display names and plural names.
/// Use [DocumentLinkType.fromString] to convert DB values.
enum DocumentLinkType {
  receipt,
  permit,
  contract,
  invoice,
  warranty,
  general;

  String get displayName => switch (this) {
        DocumentLinkType.receipt => 'Receipt',
        DocumentLinkType.permit => 'Permit',
        DocumentLinkType.contract => 'Contract',
        DocumentLinkType.invoice => 'Invoice',
        DocumentLinkType.warranty => 'Warranty',
        DocumentLinkType.general => 'General',
      };

  String get pluralName => switch (this) {
        DocumentLinkType.receipt => 'Receipts',
        DocumentLinkType.permit => 'Permits',
        DocumentLinkType.contract => 'Contracts',
        DocumentLinkType.invoice => 'Invoices',
        DocumentLinkType.warranty => 'Warranties',
        DocumentLinkType.general => 'General',
      };

  static DocumentLinkType fromString(String s) => switch (s) {
        'receipt' => DocumentLinkType.receipt,
        'permit' => DocumentLinkType.permit,
        'contract' => DocumentLinkType.contract,
        'invoice' => DocumentLinkType.invoice,
        'warranty' => DocumentLinkType.warranty,
        _ => DocumentLinkType.general,
      };
}
