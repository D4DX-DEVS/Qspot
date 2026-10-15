import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../../../utils/dob_format.dart';
import '../model/user_model.dart';

/// State for the "add your date of birth" screen shown to a signed-in student
/// or teacher whose account has none: the picked date and saving it to the
/// account.
class DobRequiredProvider extends ChangeNotifier {
  DobRequiredProvider({
    required this.applyUser,
    this.role,
    Future<UserModel> Function(String dob)? saveDob,
  }) : _saveDob = saveDob ?? ((dob) => _saveToAccount(dob, role));

  /// Called with the saved profile so the app uses it at once.
  final Future<void> Function(UserModel user) applyUser;

  /// The signed-in account's role; teachers save through their own route and
  /// go on to the faculty screen.
  final String? role;
  final Future<UserModel> Function(String dob) _saveDob;

  bool get isFaculty => role == 'faculty';

  DateTime? _dob;
  bool _saving = false;
  String? _errorMessage;

  DateTime? get dob => _dob;
  String? get dobText => _dob == null ? null : formatDobForApi(_dob!);
  bool get isSaving => _saving;
  String? get errorMessage => _errorMessage;
  bool get canSave => _dob != null && !_saving;

  void setDob(DateTime value) {
    _dob = value;
    _errorMessage = null;
    notifyListeners();
  }

  /// Saves the picked date. Returns true when the account was updated.
  Future<bool> save() async {
    if (!canSave) return false;
    _saving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _saveDob(formatDobForApi(_dob!));
      await applyUser(user);
      _saving = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error is ApiException
          ? error.message
          : "We couldn't save your date of birth. Please try again.";
      _saving = false;
      notifyListeners();
      return false;
    }
  }

  static Future<UserModel> _saveToAccount(String dob, String? role) async {
    final response = await ApiClient.put(
      role == 'faculty' ? '/api/faculty/me/dob' : '/api/user/me',
      body: {'dob': dob},
    );
    final user = response is Map ? response['user'] : null;
    if (user is! Map) {
      throw const FormatException('The server did not return your profile');
    }
    return UserModel.fromJson(Map<String, dynamic>.from(user));
  }
}
