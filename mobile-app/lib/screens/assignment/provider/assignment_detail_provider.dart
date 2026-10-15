import 'package:flutter/foundation.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';

/// State of the assignment detail screen: the assignment request, the
/// submitting flag and the files picked for submission.
class AssignmentDetailProvider extends ChangeNotifier {
  AssignmentDetailProvider(AssignmentModel fallback)
    : _assignment = AssignmentService.fetchOne(
        fallback.id,
      ).catchError((_) => fallback);

  final Future<AssignmentModel> _assignment;
  bool _submitting = false;
  final List<AssignmentUpload> _attachments = [];

  Future<AssignmentModel> get assignment => _assignment;
  bool get submitting => _submitting;
  List<AssignmentUpload> get attachments => List.unmodifiable(_attachments);

  void setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }

  void addAttachment(AssignmentUpload file) {
    _attachments.add(file);
    notifyListeners();
  }

  void removeAttachmentAt(int index) {
    _attachments.removeAt(index);
    notifyListeners();
  }
}
