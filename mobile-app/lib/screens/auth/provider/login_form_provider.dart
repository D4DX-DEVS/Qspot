import 'package:flutter/foundation.dart';

/// Screen-local state for the login screen: which step is showing (phone or
/// OTP) and whether an OTP resend is in flight.
class LoginFormProvider extends ChangeNotifier {
  bool _otpSent = false;
  bool _isResending = false;

  bool get otpSent => _otpSent;
  bool get isResending => _isResending;

  void setOtpSent(bool value) {
    _otpSent = value;
    notifyListeners();
  }

  void setResending(bool value) {
    _isResending = value;
    notifyListeners();
  }
}
