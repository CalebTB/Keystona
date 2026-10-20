import '../models/task_completion.dart';
import '../models/task_log_draft.dart';

/// Works out which pro "A pro" starts on in the Log screen: the one who did
/// the most recent earlier completion of the task. Pure Dart.
abstract final class TaskProPrefill {
  /// The pro named on the newest earlier completion done by a pro, built from
  /// the stored contractor fields (name, company, phone). Null when no
  /// earlier completion was done by a pro, or none names one.
  static TaskPro? lastPro(List<TaskCompletion> completions) {
    final newestFirst = [...completions]
      ..sort((a, b) {
        final byDate = b.completedDate.compareTo(a.completedDate);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
    for (final c in newestFirst) {
      if (c.completedBy != TaskDoer.pro.value) continue;
      final company = _clean(c.contractorCompany);
      final name = _clean(c.contractorName) ?? company;
      if (name == null) continue;
      return TaskPro(
        id: TaskPro.storedId,
        name: name,
        company: company,
        phone: _clean(c.contractorPhone),
      );
    }
    return null;
  }

  /// [stored] as an entry of [pros] when one matches by phone number or by
  /// name (and company, when both have one); otherwise [stored] itself, which
  /// is then shown read-only, built from what was saved.
  static TaskPro resolve(TaskPro stored, List<TaskPro> pros) {
    final phone = _digits(stored.phone);
    for (final p in pros) {
      if (phone.isNotEmpty && _digits(p.phone) == phone) return p;
    }
    for (final p in pros) {
      if (_same(p.name, stored.name) && _sameCompany(p, stored)) return p;
    }
    return stored;
  }

  static bool _sameCompany(TaskPro a, TaskPro b) {
    final x = _clean(a.company);
    final y = _clean(b.company);
    return x == null || y == null || _same(x, y);
  }

  static bool _same(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static String _digits(String? v) => (v ?? '').replaceAll(RegExp(r'\D'), '');

  static String? _clean(String? v) {
    final t = v?.trim();
    return t == null || t.isEmpty ? null : t;
  }
}
