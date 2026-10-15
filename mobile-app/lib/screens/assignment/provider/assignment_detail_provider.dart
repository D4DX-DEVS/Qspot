import 'package:flutter/foundation.dart';
import 'package:qspot/screens/assignment/model/assignment_model.dart';
import 'package:qspot/screens/assignment/service/assignment_service.dart';

/// State of the assignment detail screen: the assignment request, the
/// submitting flag, the files picked for submission and whether the
/// learner's sent response is shown.
class AssignmentDetailProvider extends ChangeNotifier {
  AssignmentDetailProvider(AssignmentModel fallback)
    : _assignment = AssignmentService.fetchOne(
        fallback.id,
      ).catchError((_) => fallback);

  final Future<AssignmentModel> _assignment;
  bool _submitting = false;
  bool _responseOpen = false;
  bool _closed = false;
  final List<AssignmentUpload> _attachments = [];

  Future<AssignmentModel> get assignment => _assignment;
  bool get submitting => _submitting;

  /// The deadline has passed: the answer form is replaced by a note.
  bool isClosed(AssignmentModel assignment) => _closed || assignment.isClosed;

  /// The deadline passed while the page was open, or the server turned the
  /// work away (the phone's clock may be behind).
  void markClosed() {
    _closed = true;
    notifyListeners();
  }

  /// The sent response starts folded away.
  bool get responseOpen => _responseOpen;
  List<AssignmentUpload> get attachments => List.unmodifiable(_attachments);

  void setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }

  void toggleResponse() {
    _responseOpen = !_responseOpen;
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
