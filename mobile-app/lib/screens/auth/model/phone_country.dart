import 'phone_country_list.dart';

/// A country a phone number can be from, with how many digits a mobile number
/// has there. Every country is in [phoneCountries], generated from Google's
/// libphonenumber data by tools/phone-countries/generate.mjs, the same list
/// the API checks numbers against.
class PhoneCountry {
  const PhoneCountry({
    required this.iso,
    required this.name,
    required this.dialCode,
    required this.lengths,
    required this.trunkZero,
  });

  /// Two-letter country code, such as 'IN'.
  final String iso;
  final String name;

  /// Calling code without the "+", such as '91'.
  final String dialCode;

  /// How many digits a mobile number can have, smallest first.
  final List<int> lengths;

  /// Whether a "0" typed before the number is only what people dial inside
  /// the country (UK 07400…), not part of the number itself.
  final bool trunkZero;

  /// The default: most learners are in India.
  static final PhoneCountry india = phoneCountries.firstWhere(
    (country) => country.iso == 'IN',
  );

  bool get isIndia => iso == 'IN';

  int get maxLength => lengths.last;

  /// The flag emoji, built from the two letters of [iso].
  String get flag => String.fromCharCodes(
    iso.codeUnits.map((letter) => 0x1F1E6 + letter - 0x41),
  );

  bool acceptsLength(int length) => lengths.contains(length);

  /// "10", "9 or 10", "7 to 13".
  String get lengthLabel {
    if (lengths.length == 1) return '${lengths.first}';
    if (lengths.length == 2) return '${lengths.first} or ${lengths.last}';
    if (lengths.last - lengths.first == lengths.length - 1) {
      return '${lengths.first} to ${lengths.last}';
    }
    final allButLast = lengths.sublist(0, lengths.length - 1).join(', ');
    return '$allButLast or ${lengths.last}';
  }

  /// [typed] as a number from this country: digits only, without a leading
  /// "0" that is not part of the number, and at most [maxLength] digits.
  String cleanNumber(String typed) {
    var digits = typed.replaceAll(RegExp(r'\D'), '');
    if (trunkZero) digits = digits.replaceFirst(RegExp(r'^0+'), '');
    return digits.length > maxLength ? digits.substring(0, maxLength) : digits;
  }

  /// [number] the way the API saves it: an Indian number as its 10 digits,
  /// the way every account was saved before other countries were allowed;
  /// any other as `+<calling code><number>`.
  String forApi(String number) => isIndia ? number : '+$dialCode$number';
}
