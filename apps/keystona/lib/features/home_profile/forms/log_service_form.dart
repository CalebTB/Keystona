import 'package:flutter/widgets.dart';

import '../models/item_service_entry.dart';

/// The fields of the "Log a repair or service" sheet and the draft they make.
/// Plain Dart over text controllers, tested without any screen.
class LogServiceForm extends ChangeNotifier {
  LogServiceForm({this.editing, DateTime? today})
    : kind = editing?.kind ?? ServiceKind.service,
      date = editing?.serviceDate ?? _dayOf(today ?? DateTime.now()),
      documentId = editing?.documentId,
      underWarranty = editing?.underWarranty ?? false,
      title = TextEditingController(text: editing?.title ?? ''),
      provider = TextEditingController(text: editing?.provider ?? ''),
      cost = TextEditingController(text: _money(editing?.cost)),
      note = TextEditingController(text: editing?.note ?? '') {
    for (final c in [title, provider, cost, note]) {
      c.addListener(notifyListeners);
    }
  }

  final ItemServiceEntry? editing;
  final TextEditingController title;
  final TextEditingController provider;
  final TextEditingController cost;
  final TextEditingController note;
  ServiceKind kind;
  DateTime date;
  bool underWarranty;
  String? documentId;
  String? documentName;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _money(double? v) => v == null
      ? ''
      : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  /// The kinds offered: service and repair, plus the entry's own kind when it
  /// is being edited.
  List<ServiceKind> get kinds => [
    ServiceKind.service,
    ServiceKind.repair,
    if (editing != null &&
        editing!.kind != ServiceKind.service &&
        editing!.kind != ServiceKind.repair)
      editing!.kind,
  ];

  /// The cost, or null when empty or not a number.
  double? get costValue => double.tryParse(cost.text.trim().replaceAll(',', ''));

  bool get costInvalid {
    if (cost.text.trim().isEmpty) return false;
    final v = costValue;
    return v == null || v < 0;
  }

  bool get titleMissing => title.text.trim().isEmpty;

  /// True when the draft can be saved.
  bool get canSave => !titleMissing && !costInvalid;

  void setKind(ServiceKind value) {
    kind = value;
    notifyListeners();
  }

  void setDate(DateTime value) {
    date = _dayOf(value);
    notifyListeners();
  }

  void setUnderWarranty(bool value) {
    underWarranty = value;
    notifyListeners();
  }

  void setDocument(String? id, String? name) {
    documentId = id;
    documentName = name;
    notifyListeners();
  }

  String? _orNull(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  /// The draft to save. Call only when [canSave].
  ItemServiceDraft toDraft() => ItemServiceDraft(
    kind: kind,
    serviceDate: date,
    title: title.text.trim(),
    provider: _orNull(provider),
    cost: costValue,
    note: _orNull(note),
    underWarranty: underWarranty,
    documentId: documentId,
  );

  @override
  void dispose() {
    for (final c in [title, provider, cost, note]) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
