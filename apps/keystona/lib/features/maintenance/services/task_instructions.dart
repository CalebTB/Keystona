/// A piece of a step: plain, or **bold**.
class StepSpan {
  const StepSpan(this.text, {this.bold = false});

  final String text;
  final bool bold;
}

/// Turns the `instructions` text into numbered steps. One step per line; a
/// leading "1.", "-" or bullet is dropped; `**bold**` marks emphasis.
abstract final class TaskInstructions {
  static final RegExp _lead = RegExp(r'^\s*(?:\d+[.)]|[-*•])\s+');

  /// The non-empty steps of [text], without their numbering.
  static List<String> steps(String? text) {
    if (text == null) return const [];
    return [
      for (final line in text.split('\n'))
        if (line.replaceFirst(_lead, '').trim().isNotEmpty)
          line.replaceFirst(_lead, '').trim(),
    ];
  }

  /// [step] split into plain and bold spans.
  static List<StepSpan> spans(String step) {
    final parts = step.split('**');
    return [
      for (var i = 0; i < parts.length; i++)
        if (parts[i].isNotEmpty) StepSpan(parts[i], bold: i.isOdd),
    ];
  }
}
