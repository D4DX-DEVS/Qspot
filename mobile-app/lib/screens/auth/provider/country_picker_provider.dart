import 'package:flutter/foundation.dart';

import '../model/phone_country.dart';
import '../model/phone_country_list.dart';

/// Search state for the country picker: what was typed and the countries
/// that match it, by name, two-letter code or calling code.
class CountryPickerProvider extends ChangeNotifier {
  CountryPickerProvider({List<PhoneCountry> countries = phoneCountries})
    : _countries = countries;

  final List<PhoneCountry> _countries;
  String _query = '';

  String get query => _query;

  List<PhoneCountry> get results {
    final text = _query.trim().toLowerCase();
    if (text.isEmpty) return _countries;
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    final isCode = digits.isNotEmpty && RegExp(r'^\+?\d+$').hasMatch(text);
    return _countries.where((country) {
      if (isCode) return country.dialCode.startsWith(digits);
      return country.name.toLowerCase().contains(text) ||
          country.iso.toLowerCase() == text;
    }).toList();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }
}
