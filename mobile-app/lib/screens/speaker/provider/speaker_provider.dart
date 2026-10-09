import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/speaker_model.dart';
import '../../../utils/api_urls.dart';
import '../../../utils/user_friendly_error.dart';

enum SpeakerLoadingState { idle, loading, loaded, error }

class SpeakerProvider with ChangeNotifier {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // State variables
  SpeakerLoadingState _loadingState = SpeakerLoadingState.idle;
  String _errorMessage = '';

  // Speaker data
  List<SpeakerModel> _speakers = [];
  SpeakerModel? _selectedSpeaker;

  // Getters
  SpeakerLoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  List<SpeakerModel> get speakers => _speakers;
  SpeakerModel? get selectedSpeaker => _selectedSpeaker;

  bool get isLoading => _loadingState == SpeakerLoadingState.loading;
  bool get hasError => _loadingState == SpeakerLoadingState.error;
  bool get isEmpty =>
      _speakers.isEmpty && _loadingState == SpeakerLoadingState.loaded;

  /// Loads a known list without hitting the API (widget tests).
  @visibleForTesting
  void seedSpeakers(List<SpeakerModel> speakers) {
    _speakers = speakers;
    _loadingState = SpeakerLoadingState.loaded;
    notifyListeners();
  }

  // Initialize and load all speaker data
  Future<void> initialize() async {
    await _setLoadingState(SpeakerLoadingState.loading);

    try {
      await fetchSpeakers();
      await _setLoadingState(SpeakerLoadingState.loaded);
    } catch (e) {
      await _handleError('We couldn’t load speakers. ${userFriendlyError(e)}');
    }
  }

  // Fetch all speakers - Direct API call
  Future<void> fetchSpeakers() async {
    try {
      final uri = Uri.parse(ApiUrls.speakersEndpoint);

      debugPrint('👥 [SPEAKERS] Fetching speakers from: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(_timeoutDuration);

      debugPrint('👥 [SPEAKERS] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        // Handle both array response (new API) and object with data field (old API)
        final List<dynamic> speakersJson = jsonResponse is List
            ? jsonResponse
            : (jsonResponse['data'] ?? []);

        // Trust the order the API returns.
        _speakers = speakersJson
            .map((json) => SpeakerModel.fromJson(json))
            .toList();

        debugPrint('👥 [SPEAKERS] Loaded ${_speakers.length} speakers');
        notifyListeners();
      } else {
        throw Exception('Failed to fetch speakers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('👥 [SPEAKERS] Error: $e');
      rethrow;
    }
  }

  // Fetch speaker by ID - Direct API call
  Future<void> fetchSpeakerById(String id) async {
    try {
      final uri = Uri.parse('${ApiUrls.speakersEndpoint}/$id');

      debugPrint('👥 [SPEAKER BY ID] Fetching speaker: $id');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(_timeoutDuration);

      debugPrint('👥 [SPEAKER BY ID] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        // Handle both direct object response (new API) and object with data field (old API)
        final dynamic speakerJson =
            jsonResponse is Map && jsonResponse.containsKey('data')
            ? jsonResponse['data']
            : jsonResponse;

        if (speakerJson != null) {
          _selectedSpeaker = SpeakerModel.fromJson(speakerJson);

          // Also add to speakers list if not already present
          final index = _speakers.indexWhere((s) => s.id == id);
          if (index == -1) {
            _speakers.add(_selectedSpeaker!);
          } else {
            _speakers[index] = _selectedSpeaker!;
          }

          debugPrint('👥 [SPEAKER BY ID] Loaded: ${_selectedSpeaker!.name}');
          notifyListeners();
        }
      } else {
        throw Exception('Failed to fetch speaker: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('👥 [SPEAKER BY ID] Error: $e');
      throw Exception(userFriendlyError(e));
    }
  }

  // Set selected speaker
  void setSelectedSpeaker(SpeakerModel? speaker) {
    _selectedSpeaker = speaker;
    notifyListeners();
  }

  // Get speaker by ID from local list
  SpeakerModel? getSpeakerById(String id) {
    try {
      return _speakers.firstWhere((speaker) => speaker.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get speakers by IDs (for video speaker lists)
  List<SpeakerModel> getSpeakersByIds(List<String> ids) {
    return _speakers.where((speaker) => ids.contains(speaker.id)).toList();
  }

  // Search speakers by name or organization (preserves order)
  List<SpeakerModel> searchSpeakers(String query) {
    if (query.isEmpty) return _speakers;

    final lowerQuery = query.toLowerCase();
    final filtered = _speakers.where((speaker) {
      return speaker.name.toLowerCase().contains(lowerQuery) ||
          speaker.organization.toLowerCase().contains(lowerQuery) ||
          speaker.title.toLowerCase().contains(lowerQuery);
    }).toList();

    // Maintain order (already sorted by orderValue in _speakers)
    return filtered;
  }

  // Refresh speakers data
  Future<void> refresh() async {
    await _setLoadingState(SpeakerLoadingState.loading);

    try {
      await fetchSpeakers();
      await _setLoadingState(SpeakerLoadingState.loaded);
    } catch (e) {
      await _handleError(
        'We couldn’t refresh speakers. ${userFriendlyError(e)}',
      );
    }
  }

  // Private helper methods
  Future<void> _setLoadingState(SpeakerLoadingState state) async {
    _loadingState = state;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _handleError(String message) async {
    _loadingState = SpeakerLoadingState.error;
    _errorMessage = message;
    debugPrint('SpeakerProvider Error: $message');
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _speakers.clear();
    _selectedSpeaker = null;
    _loadingState = SpeakerLoadingState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
