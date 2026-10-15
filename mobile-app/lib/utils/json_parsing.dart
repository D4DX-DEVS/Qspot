/// Small defensive readers for values coming from APIs and cached JSON.
///
/// Admin-edited fields can arrive as either numbers or numeric strings. The
/// UI should fall back to a safe default instead of throwing during parsing.
int? jsonInt(dynamic value) {
  if (value is num) return value.isFinite ? value.toInt() : null;
  final raw = value?.toString().trim() ?? '';
  final integer = int.tryParse(raw);
  if (integer != null) return integer;
  final decimal = double.tryParse(raw);
  if (decimal == null || !decimal.isFinite || decimal != decimal.truncate()) {
    return null;
  }
  return decimal.toInt();
}

double? jsonDouble(dynamic value) {
  if (value is num) return value.isFinite ? value.toDouble() : null;
  final parsed = double.tryParse(value?.toString().trim() ?? '');
  return parsed?.isFinite == true ? parsed : null;
}
