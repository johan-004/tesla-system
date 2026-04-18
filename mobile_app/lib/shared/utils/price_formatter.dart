class PriceFormatter {
  static String format(dynamic raw) {
    final value = parse(raw);
    final isNegative = value < 0;
    final absolute = value.abs();
    final fixed = absolute.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = _addThousands(parts[0]);
    final decimalPart = parts.length > 1 ? parts[1] : '00';
    final formatted = '$integerPart.$decimalPart';

    return isNegative ? '-$formatted' : formatted;
  }

  static String formatCopLatino(dynamic raw) {
    final value = parse(raw);
    final isNegative = value < 0;
    final absolute = value.abs();
    final fixed = absolute.toStringAsFixed(2);
    final parts = fixed.split('.');
    final integerPart = _addThousandsWithSeparator(parts[0], '.');
    final decimalPart = parts.length > 1 ? parts[1] : '00';
    final formatted = '$integerPart,$decimalPart';

    return isNegative ? '-\$$formatted' : '\$$formatted';
  }

  static String formatCopWhole(dynamic raw) {
    final value = parse(raw).round();
    final isNegative = value < 0;
    final absolute = value.abs();
    final integerPart = _addThousandsWithSeparator(
      absolute.toString(),
      '.',
    );
    final formatted = '\$$integerPart';

    return isNegative ? '-$formatted' : formatted;
  }

  static double parse(dynamic raw) {
    if (raw == null) {
      return 0;
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return 0;
    }

    final sanitized =
        text.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(' ', '').trim();
    if (sanitized.isEmpty ||
        sanitized == '-' ||
        sanitized == '.' ||
        sanitized == ',') {
      return 0;
    }

    final normalized = _normalizeNumericString(sanitized);
    return double.tryParse(normalized) ?? 0;
  }

  static bool isValid(String raw) {
    final sanitized =
        raw.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(' ', '').trim();
    if (sanitized.isEmpty || !RegExp(r'\d').hasMatch(sanitized)) {
      return false;
    }

    final parsed = parse(raw);
    return parsed.isFinite;
  }

  static String normalize(String raw) => parse(raw).toStringAsFixed(2);

  static String _addThousands(String digits) {
    return _addThousandsWithSeparator(digits, ',');
  }

  static String _addThousandsWithSeparator(String digits, String separator) {
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(separator);
      }
    }

    return buffer.toString();
  }

  static String _normalizeNumericString(String input) {
    final hasDot = input.contains('.');
    final hasComma = input.contains(',');
    var value = input;

    if (hasDot && hasComma) {
      final lastDot = value.lastIndexOf('.');
      final lastComma = value.lastIndexOf(',');
      final decimalSeparator = lastDot > lastComma ? '.' : ',';
      final thousandsSeparator = decimalSeparator == '.' ? ',' : '.';

      value = value.replaceAll(thousandsSeparator, '');
      if (decimalSeparator == ',') {
        value = value.replaceAll(',', '.');
      }
      return value;
    }

    if (hasDot || hasComma) {
      final separator = hasDot ? '.' : ',';
      final occurrences = separator.allMatches(value).length;

      if (occurrences > 1) {
        return value.replaceAll(separator, '');
      }

      final index = value.indexOf(separator);
      final decimals = value.length - index - 1;
      final isLikelyThousands = decimals == 3;

      if (isLikelyThousands) {
        return value.replaceAll(separator, '');
      }

      if (separator == ',') {
        value = value.replaceAll(',', '.');
      }
    }

    return value;
  }
}
