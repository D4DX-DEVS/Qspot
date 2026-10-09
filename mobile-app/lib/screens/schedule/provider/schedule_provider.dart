import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/schedule_model.dart';
import '../../../utils/api_urls.dart';
import '../../../utils/user_friendly_error.dart';

enum ScheduleLoadingState { idle, loading, loaded, error }

class ScheduleProvider with ChangeNotifier {
  static const Duration _timeoutDuration = Duration(seconds: 10);

  // State variables
  ScheduleLoadingState _loadingState = ScheduleLoadingState.idle;
  String _errorMessage = '';

  // Schedule data
  List<ScheduleModel> _schedules = [];
  List<ScheduleModel> _upcomingSchedules = [];
  List<ScheduleModel> _completedSchedules = [];

  // Getters
  ScheduleLoadingState get loadingState => _loadingState;
  String get errorMessage => _errorMessage;
  List<ScheduleModel> get schedules => _schedules;
  List<ScheduleModel> get upcomingSchedules => _upcomingSchedules;
  List<ScheduleModel> get completedSchedules => _completedSchedules;

  bool get isLoading => _loadingState == ScheduleLoadingState.loading;
  bool get hasError => _loadingState == ScheduleLoadingState.error;
  bool get isEmpty =>
      _schedules.isEmpty && _loadingState == ScheduleLoadingState.loaded;

  // Initialize and load schedule data
  Future<void> initialize() async {
    await _setLoadingState(ScheduleLoadingState.loading);

    try {
      await fetchSchedules();
      await _setLoadingState(ScheduleLoadingState.loaded);
    } catch (e) {
      await _handleError(
        'We couldn’t load the schedule. ${userFriendlyError(e)}',
      );
    }
  }

  // Fetch all schedules
  Future<void> fetchSchedules() async {
    try {
      final uri = Uri.parse(ApiUrls.scheduleEndpoint);
      debugPrint('📅 [SCHEDULES] Fetching from: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(_timeoutDuration);

      debugPrint('📅 [SCHEDULES] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        final List<dynamic> schedulesJson = jsonResponse is List
            ? jsonResponse
            : (jsonResponse['data'] ?? []);
        final schedules = schedulesJson
            .map((json) => ScheduleModel.fromJson(json))
            .toList();

        _schedules = schedules;

        // Separate into upcoming and completed
        _upcomingSchedules = schedules
            .where((schedule) => schedule.isUpcoming || schedule.isToday)
            .toList();

        _completedSchedules = schedules
            .where((schedule) => schedule.isPast && !schedule.isToday)
            .toList();

        debugPrint(
          '📅 [SCHEDULES] Total: ${_schedules.length}, Upcoming: ${_upcomingSchedules.length}, Completed: ${_completedSchedules.length}',
        );

        notifyListeners();
      } else {
        throw Exception('Failed to fetch schedules: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('📅 [SCHEDULES] Error: $e');
      rethrow;
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await _setLoadingState(ScheduleLoadingState.loading);

    try {
      await fetchSchedules();
      await _setLoadingState(ScheduleLoadingState.loaded);
    } catch (e) {
      await _handleError(
        'We couldn’t refresh the schedule. ${userFriendlyError(e)}',
      );
    }
  }

  // Get schedule by ID
  ScheduleModel? getScheduleById(String id) {
    try {
      return _schedules.firstWhere((schedule) => schedule.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get schedules for today
  List<ScheduleModel> getTodaySchedules() {
    return _schedules.where((schedule) => schedule.isToday).toList();
  }

  // Get next upcoming schedule
  ScheduleModel? getNextSchedule() {
    if (_upcomingSchedules.isEmpty) return null;
    return _upcomingSchedules.first;
  }

  // Private helper methods
  Future<void> _setLoadingState(ScheduleLoadingState state) async {
    _loadingState = state;
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> _handleError(String message) async {
    _loadingState = ScheduleLoadingState.error;
    _errorMessage = message;
    debugPrint('ScheduleProvider Error: $message');
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _schedules.clear();
    _upcomingSchedules.clear();
    _completedSchedules.clear();
    _loadingState = ScheduleLoadingState.idle;
    _errorMessage = '';
    notifyListeners();
  }
}
