/// Form field validators for use with [flutter_form_builder].
///
/// All validators return `null` when the value is valid and a user-friendly
/// error string when invalid. They conform to the `FormFieldValidator<String>`
/// type signature so they can be passed directly to `validators:` fields.
abstract final class Validators {
  /// Fails when the field is null, empty, or only whitespace.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  /// Fails when the value is not a valid email address.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    // RFC 5322-inspired simple check. Raw strings avoid escaping issues.
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+"
      r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*'
      r'\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Fails when the value is not a recognizable phone number.
  ///
  /// Accepts formats: `+15551234567`, `555-123-4567`, `(555) 123-4567`, etc.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final stripped = value.replaceAll(RegExp(r'[\s\-().+]'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(stripped)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Returns a validator that fails when the value exceeds [max] characters.
  static String? Function(String?) maxLength(int max) {
    return (value) {
      if (value != null && value.length > max) {
        return 'Must be $max characters or fewer';
      }
      return null;
    };
  }

  /// Returns a validator that fails when the value is shorter than [min] characters.
  static String? Function(String?) minLength(int min) {
    return (value) {
      if (value == null || value.length < min) {
        return 'Must be at least $min characters';
      }
      return null;
    };
  }

  /// Fails when the value is not a positive number (greater than zero).
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'A number is required';
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed <= 0) {
      return 'Must be greater than zero';
    }
    return null;
  }

  /// Fails when the value is not a plausible year between 1800 and the current year.
  static String? year(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid year';
    }
    final currentYear = DateTime.now().year;
    if (parsed < 1800 || parsed > currentYear) {
      return 'Year must be between 1800 and $currentYear';
    }
    return null;
  }
}
