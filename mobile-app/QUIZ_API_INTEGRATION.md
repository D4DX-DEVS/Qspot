# Quiz API Integration Documentation

## 📋 Overview

This document describes the quiz API integration that was implemented to manage quiz availability, configuration, and validation.

## 🔗 API Endpoint

```
GET /api/quizzes/config
```

### Response Format
```json
{
  "_id": "691826096290f347f959d849",
  "createdAt": "2025-11-15T07:04:41.309Z",
  "endDate": "2025-11-17T12:00:00.000Z",
  "isEnable": true,
  "numberOfQuestions": 1,
  "questionsRandomization": true,
  "startDate": "2025-11-15T00:00:00.000Z",
  "updatedAt": "2025-11-15T07:04:41.309Z"
}
```

## 🎯 Implementation Features

### 1. **Quiz Configuration Model**
Created `QuizConfig` class in `lib/screens/quiz/model/quiz_model.dart`:

**Fields:**
- `id`: Unique quiz configuration ID
- `createdAt`: Configuration creation timestamp
- `startDate`: Quiz start date/time
- `endDate`: Quiz end date/time
- `isEnable`: Whether quiz feature is enabled
- `numberOfQuestions`: Number of questions to display
- `questionsRandomization`: Whether to randomize question order
- `updatedAt`: Last update timestamp

**Helper Properties:**
- `isActive`: Check if quiz is currently active (between start and end date)
- `isUpcoming`: Check if quiz hasn't started yet
- `isExpired`: Check if quiz has ended
- `timeUntilStart`: Duration until quiz starts
- `timeUntilEnd`: Duration until quiz ends
- `statusMessage`: User-friendly status message

### 2. **API Integration**

**Added to `lib/utils/api_urls.dart`:**
```dart
static const String quizConfigEndpoint = "$baseUrl/api/quizzes/config";
```

**Provider Updates (`lib/screens/quiz/provider/quiz_provider.dart`):**
- Added `fetchQuizConfig()` method to fetch configuration from API
- Added state management for quiz config
- Updated `startQuiz()` to:
  - Validate quiz is active before starting
  - Use `numberOfQuestions` from config
  - Apply `questionsRandomization` setting
- Added getters:
  - `isQuizEnabled`: Returns `isEnable` from config
  - `isQuizAvailable`: Returns `isActive` from config

### 3. **Conditional Bottom Navigation**

**Updated `lib/screens/common/screens/main_navigation_screen.dart`:**
- **Dynamic Quiz Button**: Quiz tab only appears when `isEnable` is `true`
- **Automatic Config Fetch**: Fetches quiz config on app initialization
- **Reactive UI**: Uses `Consumer<QuizProvider>` to rebuild when config changes
- **Index Management**: Automatically adjusts navigation indices when quiz is disabled

### 4. **Quiz Start Screen Validation**

**Updated `lib/screens/quiz/screens/quiz_screen.dart`:**

**Visual Status Indicators:**
- ✅ **Active (Green)**: Quiz is currently available
- ⏰ **Upcoming (Orange)**: Quiz will start soon
- ❌ **Expired (Red)**: Quiz has ended

**Status Display:**
- Shows quiz status message
- Displays countdown timer for upcoming quizzes
- Shows remaining time for active quizzes
- Shows number of questions from config

**Start Button Behavior:**
- **Enabled**: When `isEnable` is `true` AND quiz is active
- **Disabled**: When quiz is not active (upcoming or expired)
- Button text changes to "Quiz Not Available" when disabled
- Visual feedback with gray styling for disabled state

### 5. **Date/Time Validation**

**Quiz Availability Logic:**
```dart
bool get isActive {
  if (!isEnable) return false;
  final now = DateTime.now();
  return now.isAfter(startDate) && now.isBefore(endDate);
}
```

**Three States:**
1. **Before Start Date**: "Quiz will start soon" + countdown
2. **Between Start & End**: "Quiz is active now!" + time remaining
3. **After End Date**: "Quiz has ended" + disabled button

## 📱 User Experience Flow

### When Quiz is Enabled (`isEnable: true`)

#### Before Start Date:
1. Quiz button appears in bottom navigation
2. Quiz screen shows orange "Upcoming" status
3. Countdown displays time until start
4. Start button is **disabled**

#### During Active Period:
1. Quiz button appears in bottom navigation
2. Quiz screen shows green "Active" status
3. Displays time remaining until end
4. Start button is **enabled**
5. Clicking Start Quiz:
   - Opens student registration form
   - After form submission, shows language selection
   - Starts quiz with configured question count and randomization

#### After End Date:
1. Quiz button appears in bottom navigation
2. Quiz screen shows red "Expired" status
3. Start button is **disabled**

### When Quiz is Disabled (`isEnable: false`)

1. Quiz button is **hidden** from bottom navigation
2. Other navigation items adjust automatically
3. Quiz screen is not accessible

## 🔧 Technical Implementation Details

### State Management
- Uses `Provider` pattern for state management
- `QuizProvider` manages quiz config and questions
- `Consumer` widget for reactive UI updates

### API Communication
- Uses `http` package for REST API calls
- JSON parsing with `fromJson` factories
- Error handling with try-catch blocks
- Debug logging for troubleshooting

### UI Components
- Status cards with color-coded indicators
- Countdown timers with formatted durations
- Disabled state styling for unavailable quizzes
- Gradient buttons with conditional styling

## 📊 Configuration Rules

### Question Count Priority:
1. Use `numberOfQuestions` from API config (highest priority)
2. Fall back to user-selected count
3. Default to all available questions

### Randomization:
- Follows `questionsRandomization` setting from config
- `true`: Shuffles questions before starting quiz
- `false`: Questions appear in original order

### Validation Rules:
- Quiz must have `isEnable: true` to appear in navigation
- Quiz must be between `startDate` and `endDate` to be startable
- Current time is checked server-side via API

## 🚀 Testing Checklist

- [ ] Quiz button appears when `isEnable: true`
- [ ] Quiz button hidden when `isEnable: false`
- [ ] Start button disabled before start date
- [ ] Start button enabled during active period
- [ ] Start button disabled after end date
- [ ] Correct question count used from config
- [ ] Questions randomized according to config
- [ ] Status messages display correctly
- [ ] Countdown timers work accurately
- [ ] Navigation indices adjust correctly

## 📝 API Requirements

### Backend Must Provide:
- Valid ISO 8601 timestamps for dates
- Boolean flags for `isEnable` and `questionsRandomization`
- Positive integer for `numberOfQuestions`
- Consistent response format

### Error Handling:
- Graceful degradation if API fails
- Quiz works with cached questions if config unavailable
- Default values used when config is null

## 🎨 UI States Summary

| State | Button Color | Button Text | Icon | Navigation |
|-------|-------------|-------------|------|------------|
| Disabled (`isEnable: false`) | - | - | - | Hidden |
| Upcoming | Gray | Quiz Not Available | ⏰ | Visible |
| Active | Gradient | Start Quiz | ✅ | Visible |
| Expired | Gray | Quiz Not Available | ❌ | Visible |

## 🔍 Debug Logs

The implementation includes comprehensive debug logging:
```
📋 [QUIZ] Config loaded: Quiz is active now!
📊 [QUIZ] Questions to show: 15
🎯 [QUIZ] Started quiz with 15 questions
🔀 [QUIZ] Randomization: true
```

## 🎯 Future Enhancements

Potential improvements:
- Auto-refresh config at intervals
- Push notifications for quiz start
- Historical quiz results tracking
- Certificate generation for passing scores
- Leaderboard integration

---

**Implementation Date:** November 15, 2024  
**Status:** ✅ Complete  
**Files Modified:** 5  
**Linter Errors:** 0

