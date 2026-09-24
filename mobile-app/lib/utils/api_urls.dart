class ApiUrls {
  // QSPOT API. Defaults to production; override for local dev with:
  //   flutter run --dart-define=API_BASE_URL=http://localhost:5001
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: "https://qspot-api-ldzmy.ondigitalocean.app",
  );

  // Collection endpoints
  static const String videosEndpoint = "$baseUrl/api/videos";
  static const String speakersEndpoint = "$baseUrl/api/speakers";
  static const String subjectsEndpoint = "$baseUrl/api/subjects";
  static const String notificationsEndpoint = "$baseUrl/api/notifications";
  static const String askQuestionEndpoint = "$baseUrl/api/questions";
  static const String scheduleEndpoint = "$baseUrl/api/schedules";
  static const String bannerEndpoint = "$baseUrl/api/banner";

  // Quiz endpoints
  static const String quizConfigEndpoint = "$baseUrl/api/quizzes/config";
  static const String quizQuestionsEndpoint = "$baseUrl/api/quiz-questions";
  static const String quizAttemptEndpoint = "$baseUrl/api/quizzes/attempt";
}
