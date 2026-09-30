import 'package:flutter/foundation.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';

/// Holds the assignments list request for the assignments screen and
/// re-fetches it on demand.
class AssignmentsScreenProvider extends ChangeNotifier {
  AssignmentsScreenProvider() : _assignments = AssignmentService.fetchAll();

  Future<List<AssignmentModel>> _assignments;

  Future<List<AssignmentModel>> get assignments => _assignments;

  Future<void> reload() async {
    final request = AssignmentService.fetchAll();
    _assignments = request;
    notifyListeners();
    await request;
  }
}
