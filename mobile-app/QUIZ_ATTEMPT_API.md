# Quiz Attempt API Integration

## Overview
Implemented quiz attempt submission to the backend API with user authentication and duration tracking for each question.

## Changes Made

### 1. API Endpoint Added
**File:** `lib/utils/api_urls.dart`
- Added `quizAttemptEndpoint = "$baseUrl/api/quizzes/attempt"`

### 2. Quiz Model Updates
**File:** `lib/screens/quiz/model/quiz_model.dart`
- Updated `QuestionResult` class to include `duration` field (in seconds)

### 3. Duration Tracking Implementation
**File:** `lib/screens/quiz/provider/quiz_provider.dart`

Added duration tracking functionality:
- `_answerDurations`: Map to store duration for each answered question
- `_questionStartTimes`: Map to track when each question was first shown
- `_quizStartTime`: Tracks when the entire quiz started

**Key Features:**
- **Total Quiz Timer**: Starts when quiz begins, tracks entire quiz duration
- **Per-Question Timer**: Starts automatically when a question is displayed
- Duration is calculated when an answer is selected
- Timer continues tracking even when navigating between questions
- Final duration is calculated on quiz submission for any unanswered questions
- Total duration sent to API in seconds

### 4. API Submission Implementation
**File:** `lib/screens/quiz/provider/quiz_provider.dart`

Added two new methods:

#### `_getAuthToken()`
- Retrieves auth token from SharedPreferences
- Returns `null` if token is not found

#### `submitQuizAttempt()`
- Calculates quiz results on-the-fly (doesn't require `_quizResult` to be set)
- Can be called before `submitQuiz()` to prevent widget lifecycle issues
- Submits quiz results to the API with the following payload:
  ```json
  {
    "language": "English" | "Malayalam",
    "questions": [
      {
        "totalNumberOfQuestions": 3,
        "questionNumber": "1",
        "question": "What is 2 + 2?",
        "options": ["3", "4", "5", "6"],
        "correctAnswer": "4"
      }
    ],
    "answers": [
      {
        "attemptedAnswer": "4",
        "isCorrect": true,
        "duration": 12
      }
    ],
    "score": 3,
    "percentage": 100,
    "totalDuration": 47
  }
  ```

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer {token}`

**Response Handling:**
- Returns success/failure status
- Includes error messages if submission fails

### 5. UI Integration
**File:** `lib/screens/quiz/screens/quiz_question_screen.dart`

Updated the submit quiz dialog with improved async handling:
- Shows loading dialog while submitting
- Calls `submitQuizAttempt()` first (API submission with on-the-fly calculation)
- Then calls `submitQuiz()` (local result storage and screen transition)
- Shows success/failure SnackBar message after results screen loads
- Green SnackBar for successful submission
- Orange SnackBar for failed submission
- Prevents widget lifecycle errors with proper context checking

## Authentication Flow
1. Check if user token exists in SharedPreferences
2. If token exists, include it in the Authorization header
3. If token is missing, API submission fails with "User not authenticated" message

## Error Handling
- Network errors are caught and returned with appropriate messages
- Missing token returns error before API call
- Missing quiz questions returns error immediately
- API errors are parsed and displayed to the user
- Widget lifecycle errors prevented by proper context checking and async handling
- Context.mounted checks before all dialog/snackbar displays after async operations
- Graceful handling when user has already attempted the quiz

## Common Issues & Solutions

### 404 Error: "No quiz configuration found"
**Cause:** The backend doesn't have a quiz configuration set up for the current date/time.

**Solution:** 
1. Check if the quiz configuration exists in your backend database
2. Verify the configuration's `startDate` and `endDate` are correct
3. Ensure `isEnable` is set to `true` in the configuration
4. The app will show an orange SnackBar with the error message but won't crash

### Widget Deactivation Error / Invalid BuildContext
**Cause:** Trying to show dialog/SnackBar after screen has transitioned or context is disposed.

**Solution:** Already fixed in the current implementation:
- API submission happens first
- Loading dialog shows during submission
- Screen transitions after API completes
- SnackBar shows with a delay after results screen loads
- **`context.mounted` checks before all dialog/snackbar operations**
- Graceful degradation if context is no longer valid

### 400 Error: "You have already submitted a quiz attempt"
**Cause:** User is trying to take the quiz again after already submitting.

**Solution:** Already handled in the current implementation:
1. API detects the duplicate attempt and returns 400 error
2. `hasAlreadyAttempted` flag is set in QuizProvider
3. Alert dialog shows: "Already Attempted" with explanation
4. Quiz is reset to start screen
5. Subsequent attempts to start quiz are blocked at the beginning
6. Uses `context.mounted` checks to prevent widget errors

## Duration Tracking Logic

### Total Duration
- Starts: When quiz begins (in `startQuiz()`)
- Ends: When quiz is submitted (in `submitQuizAttempt()`)
- Measures: Complete time from quiz start to submission

### Per-Question Duration
1. **Quiz Start:** Timer starts for the first question
2. **Answer Selection:** Duration is recorded when answer is selected
3. **Question Navigation:** Timer starts for new questions not yet viewed
4. **Quiz Submission:** Final durations calculated for any unrecorded questions

## Testing Checklist
- [ ] Quiz starts successfully and first question timer begins
- [ ] Total duration timer starts when quiz begins
- [ ] Per-question duration is recorded when selecting an answer
- [ ] Timer continues properly when navigating between questions
- [ ] Loading dialog appears when submitting quiz
- [ ] API submission happens before screen transition
- [ ] Results screen appears after API submission completes
- [ ] Quiz submission calculates results correctly
- [ ] API call includes correct payload structure with totalDuration field
- [ ] Total duration is calculated correctly (in seconds)
- [ ] Auth token is retrieved from SharedPreferences
- [ ] Success message shown on successful submission (green SnackBar)
- [ ] Error message shown when token is missing (orange SnackBar)
- [ ] Error message shown on network failure (orange SnackBar)
- [ ] Error message shown for 404 configuration error (orange SnackBar)
- [ ] Language (English/Malayalam) is correctly included in payload
- [ ] No widget lifecycle errors occur during submission

## Debug Logs
The implementation includes extensive debug logging:
- `⏱️ [QUIZ]` - Duration tracking logs
- `🔑 [QUIZ]` - Auth token retrieval logs
- `📤 [QUIZ]` - API request logs
- `📥 [QUIZ]` - API response logs
- `❌ [QUIZ]` - Error logs

## Notes
- Duration is measured in seconds
- Empty/unanswered questions will have duration = 0
- The quiz config from API controls number of questions and randomization
- User must be authenticated (have a valid token) to submit quiz attempts

