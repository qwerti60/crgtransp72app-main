import 'package:flutter/material.dart';

/// Справочники (vidg, vidk, cities): уникальные значения и сопоставление с БД.
class ReferenceDropdown {
  static List<String> uniqueFieldValues(
    List<dynamic> rows, {
    String field = 'name',
  }) {
    final seen = <String>{};
    final out = <String>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final raw = row[field];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);
      out.add(value);
    }
    return out;
  }

  /// «до 5» → «до 5 т.» если в справочнике только полное название.
  static String? resolveValue(String? saved, List<String> options) {
    if (saved == null) return null;
    final needle = saved.trim();
    if (needle.isEmpty) return null;
    if (options.contains(needle)) return needle;

    final lower = needle.toLowerCase();
    for (final option in options) {
      if (option.trim().toLowerCase() == lower) return option;
    }
    for (final option in options) {
      final optionLower = option.trim().toLowerCase();
      if (optionLower.contains(lower) || lower.contains(optionLower)) {
        return option;
      }
    }
    return needle;
  }

  static List<DropdownMenuItem<String>> menuItems(
    List<String> options, {
    String? currentValue,
    TextStyle? style,
  }) {
    final values = <String>[...options];
    final current = currentValue?.trim();
    if (current != null && current.isNotEmpty && !values.contains(current)) {
      values.insert(0, current);
    }

    final seen = <String>{};
    return values
        .where((v) => seen.add(v))
        .map(
          (v) => DropdownMenuItem<String>(
            value: v,
            child: Text(v, style: style),
          ),
        )
        .toList();
  }

  static const TextStyle defaultItemStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Colors.black38,
    fontSize: 16.0,
  );
}
