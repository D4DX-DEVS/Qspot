import 'package:flutter_test/flutter_test.dart';
import 'package:qspot/screens/auth/model/phone_country.dart';
import 'package:qspot/screens/auth/model/phone_country_list.dart';
import 'package:qspot/screens/auth/provider/country_picker_provider.dart';

PhoneCountry _country(String iso) =>
    phoneCountries.firstWhere((country) => country.iso == iso);

void main() {
  group('PhoneCountry', () {
    test('India is the default, with 10 digits and the 🇮🇳 flag', () {
      final india = PhoneCountry.india;
      expect(india.dialCode, '91');
      expect(india.lengths, [10]);
      expect(india.flag, '🇮🇳');
    });

    test('each country has its own number of digits', () {
      expect(_country('AE').lengths, [9]);
      expect(_country('US').lengths, [10]);
      expect(_country('QA').lengths, [8]);
      expect(_country('DE').acceptsLength(10), isTrue);
      expect(_country('DE').acceptsLength(11), isTrue);
      expect(_country('DE').acceptsLength(9), isFalse);
    });

    test('the digit count reads naturally in a sentence', () {
      expect(PhoneCountry.india.lengthLabel, '10');
      expect(_country('DE').lengthLabel, '10 or 11');
      expect(_country('AT').lengthLabel, '7 to 13');
    });

    test('a leading 0 is dropped only where it is not part of the number', () {
      expect(_country('GB').cleanNumber('07400 123456'), '7400123456');
      expect(_country('CI').cleanNumber('0712345678'), '0712345678');
      expect(_country('AE').cleanNumber('9876543210'), '987654321');
    });

    test('an Indian number goes to the API as before, others with +code', () {
      expect(PhoneCountry.india.forApi('9876543210'), '9876543210');
      expect(_country('AE').forApi('501234567'), '+971501234567');
    });
  });

  group('CountryPickerProvider', () {
    test('lists every country until something is typed', () {
      expect(CountryPickerProvider().results, phoneCountries);
    });

    test('finds a country by name, code or calling code', () {
      final picker = CountryPickerProvider()..setQuery('emirates');
      expect(picker.results.map((c) => c.iso), ['AE']);

      picker.setQuery('+971');
      expect(picker.results.map((c) => c.iso), ['AE']);

      picker.setQuery('gb');
      expect(picker.results.map((c) => c.iso), contains('GB'));

      picker.setQuery('zzz');
      expect(picker.results, isEmpty);
    });
  });
}
