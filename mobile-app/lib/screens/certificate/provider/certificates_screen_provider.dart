import 'package:flutter/foundation.dart';

import '../../../utils/user_friendly_error.dart';
import '../model/certificate_model.dart';
import '../service/certificate_service.dart';

/// The certificates list: loading, error and the loaded items.
class CertificatesScreenProvider extends ChangeNotifier {
  CertificatesScreenProvider({Future<List<CertificateModel>> Function()? fetch})
    : _fetch = fetch ?? CertificateService.fetchMine;

  final Future<List<CertificateModel>> Function() _fetch;

  List<CertificateModel> _items = const [];
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  List<CertificateModel> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;

  /// First load: nothing to show yet.
  bool get showSkeleton => _loading && _items.isEmpty && _error == null;

  /// Failed with nothing cached to fall back on.
  bool get showError => !_loading && _error != null && _items.isEmpty;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _items = await _fetch();
    } catch (e) {
      debugPrint('Certificates load failed: $e');
      _error = userFriendlyError(e);
    } finally {
      _loading = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
