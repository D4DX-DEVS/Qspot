import 'phone_country.dart';

/// What the registration screen hands back to the sign-in screen once the
/// account exists: the name and phone number (and its country) to sign in
/// with.
typedef RegisteredAccount = ({String name, String phone, PhoneCountry country});
