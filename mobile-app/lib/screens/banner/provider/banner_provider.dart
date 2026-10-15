import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/banner_model.dart';
import '../../../utils/api_urls.dart';
import '../../../utils/user_friendly_error.dart';

enum BannerLoadingState { idle, loading, loaded, error }

class BannerProvider with ChangeNotifier {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  BannerLoadingState _loadingState = BannerLoadingState.idle;
  String _errorMessage = '';
  List<BannerModel> _banners = [];

  BannerLoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  List<BannerModel> get banners => _banners;

  bool get isLoading => _loadingState == BannerLoadingState.loading;
  bool get hasError => _loadingState == BannerLoadingState.error;
  bool get isEmpty =>
      _banners.isEmpty && _loadingState == BannerLoadingState.loaded;
  bool get hasBanners => _banners.isNotEmpty;

  Future<void> initialize() async {
    await _setLoadingState(BannerLoadingState.loading);
    try {
      await fetchBanners();
      await _setLoadingState(BannerLoadingState.loaded);
    } catch (e) {
      await _handleError('We couldn’t load banners. ${userFriendlyError(e)}');
    }
  }

  Future<void> fetchBanners() async {
    try {
      final uri = Uri.parse(ApiUrls.bannerEndpoint);
      debugPrint('🎨 [BANNERS] Fetching from: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(_timeoutDuration);

      debugPrint('🎨 [BANNERS] Status Code: ${response.statusCode}');
      debugPrint('🎨 [BANNERS] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        debugPrint(
          '🎨 [BANNERS] JSON Response Type: ${jsonResponse.runtimeType}',
        );
        final List<dynamic> bannersJson = jsonResponse is List
            ? jsonResponse
            : (jsonResponse['data'] ?? []);
        debugPrint('🎨 [BANNERS] Banners JSON Length: ${bannersJson.length}');
        _banners = bannersJson
            .map((json) => BannerModel.fromJson(json))
            .toList();
        debugPrint('🎨 [BANNERS] Loaded ${_banners.length} banners');
        if (_banners.isNotEmpty) {
          debugPrint(
            '🎨 [BANNERS] First banner ID: ${_banners[0].id}, Image: ${_banners[0].image}',
          );
          debugPrint(
            '🎨 [BANNERS] First banner Image URL: ${_banners[0].imageUrl}',
          );
        }
        notifyListeners();
      } else {
        throw Exception('Failed to fetch banners: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🎨 [BANNERS] Error: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await _setLoadingState(BannerLoadingState.loading);
    try {
      await fetchBanners();
      await _setLoadingState(BannerLoadingState.loaded);
    } catch (e) {
      await _handleError(
        'We couldn’t refresh banners. ${userFriendlyError(e)}',
      );
    }
  }

  Future<void> _setLoadingState(BannerLoadingState state) async {
    _loadingState = state;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _handleError(String message) async {
    _loadingState = BannerLoadingState.error;
    _errorMessage = message;
    debugPrint('BannerProvider Error: $message');
    notifyListeners();
  }

  void clear() {
    _banners.clear();
    _loadingState = BannerLoadingState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
