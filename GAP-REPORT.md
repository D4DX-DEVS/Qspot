# QSPOT — Gap & Defect Report

**Audit date:** 2026-09-19 · Read from the working tree (including uncommitted work). Companion to `PLAN.md` (vision) and `REVAMP.md` (yesterday's status; now stale on the course / video-progress / video-question work).

**Who this is for:** the developer (or coding agent) who will fix things. Every item has a file:line. Items are grouped by priority, then by layer. Fix in order: P0 → P1 → P2. P3/P4 are product decisions and cleanups.

Paths: `API/` = `Qspot-API/`, `ADM/` = `Qspot-admin/src/`, `APP/` = `mobile-app/lib/`.

---

## 0. Summary

| Layer | State |
|---|---|
| **API** | 17 route files, 15 models. Works, but admin auth is broken (any student token is an admin), scoring/answer keys are client-trusted or leaked, no cascade deletes, video file upload cannot succeed, and `course` is an island model with no link to subjects or videos. |
| **Admin** | 16 pages, flat 13-item sidebar. All routes exist server-side. Three visual generations, no shared API client, no 401 handling, Retry never recovers on 8 pages, many duplicated components. Domain hierarchy (course → subject → video → questions/content) is not reflected; zero cross-links between related entities. |
| **Mobile** | Flutter, no named routes. Registration leaves a token-less "logged-in" session, `user.id` is always null, quiz question ids collide, bundled JSON masks a missing quiz, resume position uses device cache not the account, video-quiz results are never shown after the session, logout leaks previous user's local data. Directus leftovers and ~10 unused packages. |
| **Cross-cutting** | Three "questions" concepts (student Q&A, quiz questions, video questions) with duplicated schemas and naming collisions. No per-user progress aggregate, no user-visible history, no roles, no moderation, no consent/age handling for minors (see `PLAN.md` §12). |

Note: `APP/screens/home/screens/home_screen.dart` was being edited by another session during the audit; its line numbers may have shifted.

---

## P0 — Security (fix before anything else)

### P0-1 Any logged-in student is an admin
`API/middlewares/auth.js:4-19` `authenticateToken` verifies the JWT signature only and never checks `role`. User tokens are signed with the same `JWT_SECRET` (`API/routes/users.js:124-128`, `role:'user'`). Every route guarded by `authenticateToken` accepts a student token: user list with phone numbers (`API/routes/admin.js:71`), user delete (`:151`), all content CRUD, quiz answer keys (`API/routes/quizQuestions.js:143`), attempt deletion (`API/routes/quizzes.js:304`). Only `quizQuestions.js:88` and `videoQuestions.js:69` look at `role`, and only to pick a response shape.
**Fix:** in `authenticateToken`, reject unless `user.role === 'admin'`; keep `optionalToken` as-is for the dual-shape routes.

### P0-2 Answer keys shipped to the client
- `API/routes/quizQuestions.js:103-120` public branch returns `correct_answer` (as an index) to anyone, no token needed.
- `API/routes/videoQuestions.js:76-78` same for video questions.
- Mobile depends on this: `APP/screens/quiz/provider/quiz_provider.dart:199-215` and `APP/services/video_progress_service.dart:213-216`.
**Fix:** strip `correct_answer` from non-admin responses (the unused `API/routes/userQuizzes.js:45` already does this correctly) and grade on the server (P0-3).

### P0-3 Client-computed scores are trusted
`API/routes/quizzes.js:199,281-290` stores client-supplied `score`, `percentage`, `answers[].isCorrect`, and even `questions[].correctAnswer`. Leaderboards (`/stats`, `/quiz-definitions/:id/results`) rank on these. Mobile computes them in `quiz_provider.dart:337-392,497-560`.
**Fix:** accept `{quizId, language, answers:[{questionId, attemptedAnswer, duration}]}`, look up the questions, compute score server-side (mirror `API/routes/userVideoQuiz.js:60-88`). Store served question ids on the attempt (see P3-6).

### P0-4 Video completion is spoofable
`API/routes/videoProgress.js:111` marks complete when `ended === true` regardless of watched seconds; `durationSeconds` is client-supplied (`:90,102-104`). `{duration:1, watchedDelta:1}` completes any video. Model comment (`API/models/videoProgress.js:3-5`) claims the opposite.
**Fix:** store duration on the video (or accept it only on first heartbeat and cap subsequent ones), drop the `ended` shortcut, and require `watchedSeconds >= COMPLETION_RATIO * duration`.

### P0-5 Video-quiz can be resubmitted until 100%
`API/routes/userVideoQuiz.js:90-102` upserts. Mobile "Try again" (`APP/screens/video/screens/video_questions_screen.dart:107,216`) silently overwrites the server attempt.
**Fix:** either lock after first submit (409) or store an attempt history and keep the first/best per policy.

### P0-6 Public student PII
`API/routes/questions.js:13,17-38` public `GET /api/questions` and `/:id` expose every asker's `name` and `class` with no auth. Audience is school children.
**Fix:** require `authenticateUser`, and/or drop `user` from the public projection.

### P0-7 Auth hygiene
- `API/routes/users.js:88-97,108-115` TEST_LOGIN/TEST_OTP backdoor active whenever the env vars are set; not gated to non-production. Gate on `NODE_ENV !== 'production'`.
- `API/routes/users.js:65-71,24-30` phone enumeration via distinct "not registered" / "already exists" messages, no rate limiting.
- `API/routes/users.js:130` login returns the full Mongoose user doc.
- `API/routes/admin.js:39` plaintext password fallback.
- `API/services/otpWhatsapp.js:5,16-19` OTP store is in-memory (lost on restart, breaks with >1 instance); `normalizePhone` is a no-op so `+91xxx` and `xxx` are different users.
- `dev.sh:56-58` prints the admin password and test logins in a tracked file. Move to `.env`.
- `API/server.js:16` CORS wide open, no helmet, no request logging, no global JSON error handler, no 404 handler.

---

## P1 — Correctness bugs (things that are wrong today)

### API

| # | Bug | Where | Fix |
|---|---|---|---|
| A1 | Video file upload cannot succeed: `fileFilter` allows only images/pdf and default limit is 5 MB, yet `POST/PUT /api/videos` runs `upload.single('video')`. Only URL videos work. | `API/services/cdnStorageService.js:46-56,104`; `API/routes/videos.js:22-24,83-90` | Add video mime types + a video-size limit, or remove the multipart path and make the admin URL-only explicitly. |
| A2 | Multer errors surface as HTML 500 on banner/speaker/subject/video routes (only courses and handouts convert to JSON). Admin cannot show "file too large". | `API/routes/banner.js:15-17`, `speakers.js:15-17`, `subjects.js:15-17`, `videos.js:22-24` | One global error middleware in `server.js` that returns JSON for MulterError. |
| A3 | Express 5: `req.body` is `undefined` when no JSON body is sent; 22 handlers destructure it unguarded → TypeError 500 instead of 400. | `admin.js:11,109`, `notifications.js:38,67`, `questions.js:117,155,224,266`, `quizzes.js:44,106,199`, `quizDefinitions.js:76-86,152-162`, `schedules.js:53,87`, `speakers.js:49,83`, `subjects.js:47,75`, `videos.js:92,150`, `videoQuestions.js:120` | `const body = req.body || {}` or a tiny middleware. |
| A4 | No cascade / guard on delete. Deleting a video leaves videoQuestion, videoProgress, videoQuizAttempt orphans; deleting a subject leaves videos with a dangling required ref (populate → null → clients crash on `subject.name`); deleting a speaker leaves video.speaker, schedule.faculty, question.faculty dangling; deleting a user leaves questions/attempts/progress; deleting a quiz leaves QuizQuestion.quizId and attempt.quizId; deleting a video question leaves attempt answers pointing nowhere. | `videos.js:311-339`, `subjects.js:153-170`, `speakers.js:131-159`, `admin.js:151-168`, `quizDefinitions.js:222-247`, `quizzes.js:176-194`, `videoQuestions.js:132-145` | Either block delete when children exist (409 with counts) or cascade. Subjects and speakers should block; videos/quizzes should cascade. |
| A5 | Race conditions: one-attempt-per-quiz is check-then-insert with no unique index (`models/quiz.js:71` only indexes `{userId, createdAt}`); `user.phone` not unique (`models/user.js:8-11`; check-then-create at `users.js:24-38`, `admin.js:123-136`); progress heartbeat is read-modify-write (`videoProgress.js:94-116`). | as listed | Unique indexes `{userId, quizId}` and `phone`; use `findOneAndUpdate` with `$inc`/`$max` for progress. |
| A6 | Populate selects non-existent field: `populate('speaker','name designation photo')` — model field is `image`. Mobile never gets a speaker picture. | `API/routes/videos.js:57,71`; `API/models/speakers.js:11` | Select `image`. |
| A7 | `GET /api/video-progress` and `/:videoId` do not include `questionCount`; only the POST does. Mobile's "Answer N questions" CTA depends on it, so it never shows for an already-completed video on a later visit. | `API/routes/videoProgress.js:18-33,36-72,118-119`; `APP/screens/video/screens/video_reels_screen.dart:548-570`, `video_player_screen.dart:500-522` | Include `questionCount` in all three responses (one aggregate for the list). |
| A8 | `videoQuizAttempt.answers.isCorrect` and `quiz.answers.isCorrect` are typed `String` ("true"/"false"). | `API/models/videoQuizAttempt.js:36-39`, `API/models/quiz.js` | Boolean. |
| A9 | `resolveActiveConfig` prefers the legacy untitled quiz even if disabled/expired, and `POST /api/quizzes/config` re-creates that doc on upsert, silently hijacking `/config`, `/attempt`, `/stats`, and public `/quiz-questions` away from any titled quiz. Admin `QuizPage` reads via the resolver (may show a titled quiz) but writes via the legacy upsert → editing what is shown can create a second quiz. | `API/services/quizConfigResolver.js:18-31`; `API/routes/quizzes.js:27-35,62-84,176-194`; `ADM/pages/QuizPage.jsx:308,342,422` | Decide Option A/B from `REVAMP.md` §4. Minimum: resolver must skip disabled/expired legacy doc; QuizPage should write to `/quiz-definitions/:id` for whatever it displays. |
| A10 | `GET /api/quizzes/stats` mixes attempts across all quizzes (attempts with no `quizId`) but prints one config's dates as if they were that quiz; the cross-quiz `rank` shown in admin is meaningless. | `API/routes/quizzes.js:370-393,401,418-424`; `ADM/pages/QuizAttemptsPage.jsx:339-347` | Scope stats by resolved quizId, or drop the unscoped view. |
| A11 | Public `GET /api/quiz-questions` returns up to 200 questions ignoring `numberOfQuestions`/`questionsRandomization`; selection is entirely client-side, and the attempt then requires `questions.length === numberOfQuestions`. | `API/routes/quizQuestions.js:104-107`; `API/routes/quizzes.js:230-232` | Serve the selected subset server-side (as `userQuizzes.js:41-44` does) and record the served ids. |
| A12 | Handouts: `POST /videos/:id/files` uploads to CDN before checking the video exists (orphans on 404); downloads store `{title,url}` only, no key, so removing a download or deleting the video never deletes the file. `getFileKeyFromUrl` exists but is unused. | `API/routes/videos.js:220-226,290-300,311-339`; `API/models/videos.js:45-52`; `API/services/cdnStorageService.js:203-218` | Store `key` on downloads; delete on removal. |
| A13 | `PUT /api/subjects/:id` deletes the old CDN image before validating/updating; a later failure leaves a subject pointing at a deleted file. | `API/routes/subjects.js:87-89` | Delete old image after successful save. |
| A14 | `PUT /api/banner/:id` requires a file, but admin's edit modal says "Leave empty to keep current image" and sends empty FormData → always 400. | `API/routes/banner.js:78-80`; `ADM/pages/BannerPage.jsx:84-94,527` | Make the file optional on PUT (nothing else to edit on a banner, so alternatively remove Edit). |
| A15 | `cdnStorageService.js:26` calls `endpoint.startsWith` on an undefined env var → TypeError → `process.exit(1)`, contradicting the "will use local storage" warning at `:12`. Duplicate `key` property at `:83,86`. | `API/services/cdnStorageService.js` | Guard env; drop the duplicate. |
| A16 | `PUT /api/video-questions/:id` re-requires `videoId`, does not verify the video exists, and uses `findByIdAndUpdate` without `runValidators`. | `API/routes/videoQuestions.js:120-123` | Make videoId optional on PUT; `runValidators: true`. |
| A17 | `PORT = process.env.PORT` implicit global; `app.listen(undefined)` picks a random port. `nodemon` is in `dependencies` and is the `start` script. | `API/server.js:83`; `API/package.json` | `const PORT = process.env.PORT || 5001`; `start: node server.js`, `dev: nodemon`. |
| A18 | `speaker.order` is a String (`''` when absent), `video.releaseDate` is a String, `question.subject` is a free String (not a ref). Videos are listed by `createdAt`, so episode order = upload order. | `API/models/speakers.js:18-20`, `API/routes/speakers.js:66`; `API/models/videos.js:30-32`, `API/routes/videos.js:57`; `API/models/question.js:13-16` | Number / Date / ObjectId ref. Add `order` (episode number) to video. |
| A19 | Missing indexes on every hot filter: `video.subject`, `video.speaker`, `QuizQuestion.quizId`, `quiz.quizId` + score/duration sort, `question.user`, `question.faculty`, `schedule.faculty`, `user.phone`, `videoQuizAttempt.videoId`. `GET /api/admin/users`, `/videos`, `/questions` unpaginated. `courses?active=true` filters in memory. Progress heartbeat does 4 queries per tick. | see agent list in §1 of API audit | Add indexes; paginate; `$inc` heartbeat. |
| A20 | Timezones: admin sends `YYYY-MM-DDTHH:mm` with no offset; server does `new Date(str)` in server-local time. Correct only when browser TZ == server TZ. | `ADM/pages/QuizzesPage.jsx:160-161`, `QuizPage.jsx:392-393`, `SchedulesPage.jsx:989-992`, `QuizAttemptsPage.jsx:65-66`; `API/routes/quizDefinitions.js:94,164-165`, `quizzes.js:50,378-379`, `schedules.js:67` | Send ISO with offset (`new Date(local).toISOString()`) from admin. |
| A21 | Mount order: `/api/user` (users router) mounted before `/api/user/video-quiz`; works only because the users router has no `/video-quiz` path. | `API/server.js:60,63` | Mount the more specific path first, or move to `/api/video-quiz`. |

### Mobile

| # | Bug | Where | Fix |
|---|---|---|---|
| M1 | Registration leaves a token-less "authenticated" session: API `POST /register` issues no token, app still marks authenticated and persists `user_data` with `token=null`; next cold start `isLoggedIn()` (checks only `user_data`) goes straight to Main with no token; every authenticated call then fails silently. | `API/routes/users.js:11-56`; `APP/screens/auth/provider/auth_provider.dart:119-121`; `APP/screens/auth/service/auth_service.dart:166-174,209-214,247-250` | Either issue a token on register (recommended: register → OTP → token) or do not set authenticated; `isLoggedIn()` must require a token. |
| M2 | `user.id` is always null: `UserModel.fromJson` reads `json['id']` but `/login/verify` returns a raw doc with `_id`. `quiz_provider.dart:401,438` reads a `'userId'` pref that is never written → all local quiz attempts stored under `'default_user'`, shared across accounts. | `APP/screens/auth/model/user_model.dart:18`; `API/routes/users.js:130`; `APP/screens/quiz/provider/quiz_provider.dart:401,438` | API: return `{id,name,phone,class,email}` (like register). App: read `_id ?? id`; write `userId` pref on login. |
| M3 | Error keys: API login errors use `error`, app reads `message` → generic "Failed to send OTP" instead of "User not registered". | `API/routes/users.js:67,117`; `APP/screens/auth/service/auth_service.dart:42,112` | Standardise on `message` (or read both). |
| M4 | Login screen has a `requiresRegistration` branch the API never sends (dead). | `APP/screens/auth/screens/login_screen.dart:370-387` | Either implement on API (unregistered phone → 404 → go to register) or remove. |
| M5 | No 401/403 handling anywhere; JWT is 24 h with no refresh. After a day: heartbeats/fetches return `{}` silently, "Jump back in" vanishes, My Questions shows "403", Ask shows raw "Invalid or expired token". Nothing sends the user to login. | `APP/services/video_progress_service.dart:150,183,197`; `APP/screens/question/screens/my_questions_screen.dart:59-71`; all providers | One HTTP client wrapper that clears session and routes to Login on 401/403. Consider longer expiry or refresh endpoint on API. |
| M6 | Logout clears only `user_data`/`auth_token`. Video progress cache, bookmarks SQLite, quiz SQLite, notification read-state, alarms, `VideoProvider._progressByVideo` survive → next user sees previous user's data. All `clear()` methods exist but are never called. | `APP/screens/auth/service/auth_service.dart:253-261` | Call every provider/service `clear()` on logout. |
| M7 | Quiz question id collision: `_id` is an ObjectId hex → `int.tryParse` always null → every question gets `DateTime.now().millisecondsSinceEpoch` in a tight loop → duplicate ids → selecting one option answers several questions; review shows wrong results. | `APP/screens/quiz/provider/quiz_provider.dart:150,275-292,337-367` | Make `id` a String holding `_id`. |
| M8 | Bundled fallback masks API state: `assets/json/quiz_questions.json` loads whenever the API returns `[]` or errors; student "takes" a quiz that doesn't exist server-side, then submit fails count validation. Hardcoded copy "Indian freedom struggle". | `quiz_provider.dart:108-119,166-169`; `APP/screens/quiz/screens/quiz_screen.dart:295` | Remove the fallback; show "no live quiz" state. |
| M9 | Submit shows results even when the server rejected; local SQLite attempt saved every time (duplicates); `hasAlreadyAttempted` never restored on launch so "Start Quiz" is always enabled. | `APP/screens/quiz/screens/quiz_question_screen.dart:383-503`; `quiz_provider.dart:386`; `loadSavedQuizAttempt` never called | Gate results on 201; add `GET /api/quizzes/attempt/mine?quizId=` (see P3-5) and use it. |
| M10 | Locale toggle mid-quiz changes the submitted `language` and can throw RangeError when ML option list is shorter/empty. `startQuiz` with 0 questions → infinite spinner. | `quiz_question_screen.dart:49-58`; `quiz_provider.dart:535`; `quiz_question_screen.dart:21-25` | Lock locale at start; guard empty. |
| M11 | Nested Scaffolds: `QuizQuestionScreen`/`QuizResultsScreen` render their own AppBar inside `QuizScreen`'s Scaffold → double app bars in the tab. | `quiz_screen.dart:169-182`; `quiz_question_screen.dart:34-60`; `quiz_results_screen.dart:20-33` | One Scaffold. |
| M12 | `/api/videos` fetched three times on init and on every pull-to-refresh; `refresh()` never reloads server progress; per-subject screen re-downloads the whole list instead of `?subject=`. | `APP/screens/video/provider/video_provider.dart:96-102,132,167,206-212,282-291`; `APP/screens/subject/screens/subject_videos_screen.dart:61-68` | Fetch once; use `?subject=`. |
| M13 | Home progress goes stale: `_progressByVideo` loaded only in `initialize()`; heartbeats update a local seconds cache, not the map → "Jump back in"/badges don't move until restart. | `video_provider.dart:78-91,294-315` | Update the map from heartbeat responses. |
| M14 | Resume uses device cache, not the account: `startAt: video.progress` → new device resumes at 0 although the card says "45% watched". Server `positionSeconds` never used. | `APP/screens/video/screens/video_reels_screen.dart:145`; `video_player_screen.dart:66` | Seed `startAt` from server progress. |
| M15 | Upcoming (unreleased) videos are playable: cards disable tap for `isUpcoming` but Reels opens with `allVideos` including upcoming → swipe reaches them. | `APP/screens/video/widgets/video_card.dart:104`; `home_screen.dart` (~1113-1118); `video_list_screen.dart:142-144,216` | Filter upcoming out of the reels list (and ideally hide server-side, see P3-3). |
| M16 | CDN-uploaded (non-YouTube) videos cannot play: reels/player only handle YouTube; others → "Open in browser". `video_player`/`chewie` are declared but unused. | `video_reels_screen.dart:136-152,588-598`; `video_player_screen.dart:297-301` | Wire `video_player`/`chewie` for direct URLs, or remove the API upload path (A1). |
| M17 | Reels "Full" pushes `VideoPlayerScreen` without pausing the reel controller → two players/audio. Live streams never heartbeat → never complete; reels autoplay while player doesn't. | `video_reels_screen.dart:479-487,623-631`; `video_player_screen.dart:105` | Pause on push. |
| M18 | Cache loses content: `VideoModel.toJson` drops `learnText/learnPoints/downloads`; `fromJson` never reads back `subjectId/subjectName` → during the 1-hour cache window Learn note says "not ready yet" and subject labels vanish. | `APP/screens/video/model/video_model.dart:78-86,135-149`; `APP/services/common/storage_service.dart:168` | Round-trip all fields. |
| M19 | Practice tab lets the user start questions before completion → server 403 "Watch the video before answering" shown as generic "Could not save your answers". `GET /api/user/video-quiz` never called → prior score never shown. `locale` never passed to `VideoQuestionsScreen` → Malayalam never shown. | `APP/screens/video/widgets/video_details_sheet.dart:360-393`; `video_questions_screen.dart:74-81`; `video_reels_screen.dart:315-319`; `video_player_screen.dart:239-243` | Gate Practice on `completed`; fetch prior attempt and show it; pass locale. |
| M20 | Bookmarks: local SQLite only; `toVideoModel()` loses subject/date/learn/downloads; list uses `videoThumbnail` the API never sets → always placeholder; provider error flag is sticky. | `APP/screens/bookmark/service/bookmark_service.dart`; `bookmark_model.dart:61-69`; `bookmarks_screen.dart:229`; `bookmark_provider.dart:133-140` | Server-side bookmarks (P3-9) or at least persist the full model. |
| M21 | Notifications: Home unread badge never initialises (`NotificationProvider.initialize()` not called from Home); tap is a no-op; nothing marks read → badge == total forever. Provider string-matches `'Network error'` which never occurs. | `home_screen.dart:393-416`; `APP/screens/notification/screens/notifications_screen.dart:374-376`; `notification_provider.dart:73` | Wire initialize + markAsRead on tap. |
| M22 | Permissions prompted at cold start before any UI/login (iOS alert permission + alarm reschedule). Timezone hardcoded `Asia/Kolkata`. Schedule reminders fire at class time, stored in the "video reminders" list with fake ids. Notification tap payloads are never routed. Daily alarm uses `fullScreenIntent`, `ongoing`, FLAG_INSISTENT. | `APP/main.dart:27`; `APP/screens/schedule/service/alarm_service.dart:54,62-67,124-136,245-274,407`; `schedule_screen.dart:450-454` | Request permissions in context; use device TZ; separate reminder lists; route taps. |
| M23 | Home gating: skeleton only when all three providers load, error when any errors → one failing endpoint blanks the whole Home; Retry re-runs everything. Courses/banners fail silently. | `home_screen.dart` (~559-577); `APP/services/course_service.dart:55-66` | Per-section error states. |
| M24 | Speaker `order` sorted asc in app, desc on API/admin. Schedule faculty name looked up from SpeakerProvider instead of the populated field. `SubjectModel.displayName` lowercases everything after the first letter ("Al-fatihah"). | `APP/screens/speaker/provider/speaker_provider.dart:79`; `schedule_screen.dart:234,390`; `APP/screens/subject/model/subject_model.dart:112` | Trust API order; use populated field; drop the case transform. |
| M25 | `main.dart:57` pins `textScaler` to 1.0 (accessibility regression). Splash sets `systemNavigationBarColor` to maroon and never resets. Settings shows version `'1.0.0'` while pubspec is `1.0.6+8`; `© 2025`. | `APP/main.dart:57`; `APP/screens/common/screens/splash_screen.dart:33-40`; `APP/screens/settings/screens/settings_screen.dart:646,826` | Use `package_info_plus`; reset system UI. |
| M26 | `login_screen.dart:410-419` `setState` after `await` without `mounted`. Several `use_build_context_synchronously` from `flutter analyze` (47 issues total). | as listed | Guard with `mounted`. |

### Admin

| # | Bug | Where | Fix |
|---|---|---|---|
| D1 | No 401/403 handling; API returns 401 (missing) / 403 (expired). After 24 h every mutation fails with a generic alert while public lists keep loading, so the admin appears logged in. Token guard exists on only 3 of 16 pages. | every page; guards only `CoursesPage.jsx:49-53`, `ChapterGuidePage.jsx:46-50`, `VideoQuestionsPage.jsx:112-116` | One axios instance with interceptor (attach token, on 401/403 clear + redirect) and a route guard component. |
| D2 | Retry never recovers on 8 pages: fetchers set `loading` but never clear `error`; render is `loading ? spinner : error ? box : list`. | `AdminDashboard.jsx:89-112`, `BannerPage.jsx:37-49`, `NotificationsPage.jsx:21-33`, `QuestionsPage.jsx:105-120`, `SpeakersPage.jsx:24-47`, `SubjectsPage.jsx:72-84`, `VideosPage.jsx:792-804`, `SchedulesPage.jsx:71-83` | `setError('')` at fetch start. |
| D3 | API error bodies discarded: server returns specific 400 messages ("Phone number already exists", etc.) but pages `alert()` a fixed string. | `AdminDashboard.jsx:153,176,194`; `BannerPage.jsx:70,101,120`; `NotificationsPage.jsx:51,77,96`; `SpeakersPage.jsx:73,109,128,145`; `SubjectsPage.jsx:107,135,154,171`; `VideosPage.jsx:850,886,905`; `SchedulesPage.jsx:111,137,156` | Surface `err.response?.data?.message`. |
| D4 | Video-question editor corrupts index-stored answers: `toForm` matches `correct_answer` by option text only, falls back to index 0. API accepts numeric indices, so a row stored as `"2"` opens with option A selected and is saved wrong; list view shows no correct option for such rows. `QuizPage.jsx:108-116` handles this correctly. | `ADM/pages/VideoQuestionsPage.jsx:58-61,700-702` | Reuse QuizPage's resolver. |
| D5 | `VideoQuestionsPage` validation writes to page-level `error` rendered behind the fixed modal → "Add question" appears to do nothing. Malayalam options optional → `options_ml` saved as `["","",""]`. `type` hard-coded `'Multiple Choice'`; no `order`/reorder UI although API sorts by `order`. | `VideoQuestionsPage.jsx:225-236,416-420,730,229-231,240` | Modal-local error; require ML or make API tolerant; add order. |
| D6 | Unscoped `/admin/quiz` "Add Question" creates questions with no `quizId`; such rows are never served to the app and never appear in any quiz-scoped view. Page reachable only by URL. | `ADM/pages/QuizPage.jsx:580-582`; `API/routes/quizQuestions.js:95-101` | Require quizId; remove the unscoped mode. |
| D7 | Uploaded handouts live only in local state until "Save episode content"; switching video or navigating away discards them and orphans CDN files. | `VideoQuestionsPage.jsx:154,353-363` | Persist on upload (API can append to `downloads` in `POST /videos/:id/files`). |
| D8 | Course cover copy says "up to 10 MB" but the API limit is 5 MB. | `CoursesPage.jsx:345`; `API/routes/courses.js:37`; `cdnStorageService.js:104` | Align. |
| D9 | `SubjectSelect` labelled required but not enforced; schedule forms validate with `alert()`; speaker `order` cannot be cleared (empty string skipped). | `VideosPage.jsx:1259-1266,1419-1426`; `SchedulesPage.jsx:559,724`; `SpeakersPage.jsx:57-59,90-92` | Enforce / inline errors / send empty. |
| D10 | Stale state: CoursesPage appends saved course at end regardless of sort; every client-paginated page resets to page 1 on refetch; QuizPage search/difficulty filter and "Top Difficulty" stat operate on the current 20-row page only but look global; QuizPage double-fetches on mount; unscoped attempts view hides the filter bar though API supports it; quiz dropdown capped at 100. | `CoursesPage.jsx:158`; `AdminDashboard.jsx:86`, `BannerPage.jsx:34`, `VideosPage.jsx:789`, `SchedulesPage.jsx:68`, `QuestionsPage.jsx:102`; `QuizPage.jsx:225-249,654-692`; `QuizAttemptsPage.jsx:119,133-142,251` | Re-sort / keep page / server-side filters. |
| D11 | 12 pages navigate with `window.location.href` (full reload, state lost); logout hard-reloads. | `AdminDashboard.jsx:115`, `BannerPage.jsx:125`, `NotificationsPage.jsx:101`, `QuestionsPage.jsx:307`, `QuizAttemptDetailPage.jsx:35`, `QuizAttemptsPage.jsx:52`, `QuizPage.jsx:222`, `QuizzesPage.jsx:74`, `SchedulesPage.jsx:161`, `SpeakersPage.jsx:133`, `SubjectsPage.jsx:159`, `VideosPage.jsx:910`; `Sidebar.jsx:121` | `useNavigate`. |
| D12 | No `*` route, no error boundary, no per-page `<title>`; login redirect via 1.5 s `setTimeout`; no "already logged in" redirect on `/admin/login`. | `ADM/App.jsx`; `AdminLogin.jsx:31-41` | Add. |

---

## P2 — Contract & consistency (both sides must agree)

| # | Topic | Detail |
|---|---|---|
| C1 | **Response envelope** | Public lists are bare arrays; admin lists are `{items,total,page,limit}`; some create routes return `{message, x}` and others return the raw doc (`POST /api/video-questions`). Pick one envelope per audience and document it. |
| C2 | **Error envelope** | `{message}` in most routes, `{ok:false,error}` in `users.js`. Standardise on `{message}` (mobile reads `message`). |
| C3 | **User identity shape** | `/login/verify` returns a raw doc (`_id`), `/register` returns `{id,...}`. Return the same `{id,name,phone,class,email}` from both and issue a token from both (M1, M2). |
| C4 | **Three quiz APIs** | `/api/quizzes/config` (legacy singleton), `/api/quiz-definitions` (admin multi), `/api/user-quizzes` (public multi, unused by any client, and the only one that hides `correct_answer`). Mobile uses the legacy pair. Choose Option B from `REVAMP.md` §4 (quiz list in app via `/api/user-quizzes`), then delete the legacy routes and the resolver. |
| C5 | **Duplicate question schemas** | `QuizQuestion` and `videoQuestion` are the same shape with a different parent ref; `options_en/ml` are JSON-encoded strings in a document DB. Either merge into one `question` bank with `{quizId?, videoId?, subjectId?, tags[]}` (enables per-topic mastery from `PLAN.md` §8), or at least store options as arrays. |
| C6 | **`questionCount` on progress** | Include on every progress response (A7). |
| C7 | **Speaker photo field** | API populates `photo`, model has `image`; mobile reads `image ?? photo`. Fix the populate (A6). |
| C8 | **Unused API surface** | `GET /api/user-quizzes/*`, `GET /api/quiz-definitions/:id/questions`, `GET /api/schedules/faculty/:id`, `PUT /api/quizzes/config`, `GET /api/videos?subject=&speaker=`, all public `GET /:id` detail routes, `GET /api/user/video-quiz`. Either adopt in clients (most are better than what the clients do) or delete. |
| C9 | **Mobile leftovers** | Directus: `APP/utils/api_urls.dart:8-12,38,41`, `APP/services/common/directus_service.dart` (dead, would crash on bare array), asset fallbacks in `banner_model.dart:29`, `speaker_model.dart:47-48`, `subject_model.dart:102-103`, pubspec comment. `picsum.photos` placeholders in `video_model.dart:197,207,247`, `latest_video_card.dart:62`, `speaker_model.dart:51`, `subject_model.dart:106` (third-party requests in production UI). Remove. |

---

## P3 — Concept & relationship gaps (product decisions; verified absent by grep)

| # | Gap | Evidence | Suggested shape |
|---|---|---|---|
| R1 | **Course is an island.** `course` has no ref to subject, video, speaker, or user; nothing refs course. In the app it is only an "About this course" card on Home. No course → subject → episode hierarchy, no enrolment, no per-course progress. | `API/models/course.js`; `ADM/pages/CoursesPage.jsx`; `APP/screens/home/widgets/about_course_sheet.dart` | Add `subject.courseId` (or `course.subjectIds[]`), expose `GET /api/courses/:id` with subjects + video counts, show course as the top of the Subjects tab. |
| R2 | **No class / enrolment entity.** `user.class`, `schedule.class` are free strings. No `class` model, no user↔course link. `PLAN.md` §7/§12 needs class-scoped social and consent. | `API/models/user.js:14-17`; `API/models/schedule.js` | `classes` collection; `user.classId`; scope schedules/quizzes/notifications by class. |
| R3 | **No publish/visibility state** on video, subject, speaker, schedule, notification, quiz question, video question (only `course.isActive`, `quizConfig.isEnable`). Draft content is public immediately; "upcoming" is derived client-side from `releaseDate` string (M15). | all models | `status: draft/published` + `publishAt`; public routes filter server-side. |
| R4 | **No episode ordering.** Episode number lives in the title (`API/scripts/link-episode-speakers.js:4-6`); videos sort by `createdAt`. | `API/models/videos.js`; `API/routes/videos.js:57` | `video.order` (episode number) + sort by it within subject. |
| R5 | **No per-user history endpoints.** No `GET` for a user's own quiz attempts; video-quiz result only per video (and the app never calls it); no per-subject / per-course completion aggregate. Profile shows 3 counters computed from a map loaded once. | `API/routes/quizzes.js` (admin-only `GET /attempt/:id`); `APP/screens/profile/screens/profile_screen.dart:139-180` | `GET /api/user/progress` → `{subjects:[{subjectId, total, completed}], quizzes:[...], videoQuizzes:[...]}`; `GET /api/user/quiz-attempts`. |
| R6 | **No attempt provenance.** Standalone attempts do not store served question ids; cannot re-grade or audit. | `API/routes/userQuizzes.js:41-44` admits this; `API/models/quiz.js` | Store `questionIds[]` on attempt; server grades (P0-3). |
| R7 | **No admin analytics for video progress or video quizzes.** `VideoProgress`/`VideoQuizAttempt` are student-only routes; no aggregate, no page. No per-user page in admin (user → attempts / questions / progress). | `API/routes/videoProgress.js`, `userVideoQuiz.js`; `ADM/pages/AdminDashboard.jsx:507-616` | `GET /api/admin/videos/:id/stats`, `GET /api/admin/users/:id/activity`; a user detail page. |
| R8 | **No roles beyond one env admin.** No `role` on user; faculty are content (`speaker`), not accounts, so they cannot answer their own questions (answers typed by the env admin; `answeredBy` = admin username, which is `undefined` under P0-1). | `API/models/user.js`; `API/routes/questions.js:222,246,287` | `user.role: student/faculty/admin`; link `speaker.userId`; faculty login answers own queue. |
| R9 | **Bookmarks and chapter-guide "seen" are per device.** Bookmarks are SQLite only; guide flag is SharedPreferences. | `APP/screens/bookmark/service/bookmark_service.dart`; `APP/screens/subject/widgets/chapter_guide_sheet.dart:15-26` | `user.bookmarks[]`, `user.seenGuides[]` or small collections. |
| R10 | **Notifications are broadcast only.** No per-user targeting, read state, class scoping, or push token storage; app tap is a no-op. | `API/models/notification.js`; M21 | Add `audience` (all/class/user), `readBy[]` or per-user read table; FCM later. |
| R11 | **Student Q&A is one-way** (student → faculty) and unmoderated: no report/flag, no hide/delete by admin (`DELETE /questions/:id` is owner-only), no profanity filter. `PLAN.md` §7 wants peer doubt wall; §12 wants moderation. | `API/routes/questions.js:196-207`; `ADM/pages/QuestionsPage.jsx` | `status: open/answered/hidden`, admin delete/hide, `reports` collection; class scoping before any peer visibility. |
| R12 | **No minors compliance data.** No age/DOB, no consent record, no parent link. `PLAN.md` §12 (DPDP) is a hard requirement for the stated audience. | `API/models/user.js` | `dob`, `consent:{by, at, via:'school'|'parent'}`; block features until consented. |
| R13 | **No habit loop.** No streak, XP, badges, daily goal, "Today" screen (`PLAN.md` §5-6). Only a local daily alarm. | grep across all three codebases: none | Start with `REVAMP.md` §5 items 8-9 (client-first Today + local streak), then `xp_events`. |
| R14 | **No i18n framework.** UI is English with one Malayalam label; quiz EN/ML toggle not persisted; video questions ignore ML (M19). | `APP/pubspec.yaml` (no `flutter_localizations`); `quiz_screen.dart:72` | `flutter_localizations` + ARB; persist language pref on user. |
| R15 | **No soft-delete / audit fields** (createdBy, updatedBy) on admin content; no refresh tokens / sessions. | all models | Add when roles land (R8). |

---

## P4 — UX & information architecture

### Mobile
- **Quiz discoverability:** the Quiz entry is removed entirely when `isEnable` is false (no "coming soon"), hidden behind "More" when enabled, fetched once at startup and never refreshed (`main_navigation_screen.dart:42-45,65,245`). Reachable two ways with different back behaviour (`home_screen.dart` ~1168).
- **Search** is decorative on Home (opens VideoList without search mode, `home_screen.dart:165-168`) and substring-only over loaded titles (`video_provider.dart:374-396`).
- **Duplicate surfaces:** Ask Question implemented three times (`ask_question_screen.dart`, `settings_screen.dart:1133-1474`, `speaker_detail_screen.dart:228-453`) with three copies of the POST; Learn note as both `LearnNoteSheet` and a tab of `VideoDetailsSheet`; Faculties reachable from Home grid, More sheet, and Settings.
- **Profile** is read-only: no edit name/class, no language preference.
- **Video card** shows both server progress and a legacy local bar assuming 60-second shorts; duration badge literally says "YouTube" (`video_card.dart:459-484`; `video_model.dart:155-174`).
- **Theme:** light-only, system dark ignored; ~40 hardcoded `Colors.white/black` in reels/player/faculties; legacy `gradientStart/End`, `secondaryGray` aliases still used; `ThemeData.light()` in time picker (`settings_screen.dart:372`). `REVAMP.md` §6 palette not yet reconciled with admin (`#701845`/`#EFB078`).
- **Offline:** no connectivity check (permission declared, unused), 1-hour cache then hard error, no banner.
- **Deep links:** none (no intent filters, no `onGenerateRoute`, no universal links).

### Admin
- **Sidebar is flat and arbitrary** (13 items). Course → Subject → Video → (questions / learn / downloads) is spread over five unrelated entries (Courses, Subjects, Chapter Guide, Videos, Video Content) with zero cross-links: subject detail has no "videos" or "edit guide" (`SubjectsPage.jsx:308-400`); video cards have no "questions / content" link (`VideosPage.jsx:658-734`); Chapter Guide re-implements a subject picker. Suggested grouping: **Content** (Courses, Subjects [+guide tab], Videos [+content/questions tab]) · **Learners** (Users [+activity], Speakers [+videos/schedules], Q&A, Schedules) · **Quizzes** · **App** (Banner, Notifications).
- **Three "questions"** collide in naming: "Questions" = student Q&A, "Video Content" = per-video MCQs, quiz questions only via Quizzes → Questions (`/admin/quiz`, not in sidebar).
- `/admin/dashboard` is the Users list; no overview/home. Attempt detail shows no quiz title; attempt → user not clickable. Speakers have no path to their videos/schedules/Q&A though API filters exist.
- Mobile bottom bar exposes Users/Speakers/Subjects by array index (`Sidebar.jsx:105`).
- **Three visual generations** (legacy CRUD modals + `alert()`, dark quiz pages with raw `datetime-local`, new master-detail pages). Spinner colours, pagination styles, page padding, z-index layers all differ (details in admin audit §5). Speakers/Subjects force `grid-cols-3` at phone width with 9-11 px text; master-detail pages don't scroll to the form on phones; several multi-input rows overflow.

---

## P5 — Cleanup / hygiene

### API
- Scripts not wired into `package.json`; `seed-demo.js` seeds no course, videoQuestion, video.speaker, learn/downloads, guide; `--force` wipes users but not progress/attempt collections (orphans). `seed-from-live.js` `ID_FIELDS` lacks `speaker` — will insert the populated object verbatim once live API ships the new populate.
- `.env.example` documents `DO_HANDOUT_MAX_FILE_SIZE` that `.env` lacks (falls back to 25 MB).

### Admin
- No shared `apiClient`, `Modal`, `PageHeader`, `Pagination`, `useAuth`. `FacultySelect` ×2, calendar picker ×3, time picker ×2, `formatDuration` ×2, `cardClass/inputClass` ×3, body-scroll-lock ×~15, pagination widget ×6, placeholder SVG ×5.
- Dead: `Sidebar.jsx:109-117,152-170` parent nesting; `AdminDashboard.jsx:9,36-45` `adminInfo`; `VideosPage.jsx:45-65` thumbnail helpers; `QuizPage.jsx:187,214` messages never rendered, `:49-57,135-149` helpers; unused icon imports; `dotenv` dependency; template `README.md`. Lint (`eslint.config.js`) evidently not run.

### Mobile
- **Nested `.git` inside `mobile-app/`** (own history) while the parent repo lists the folder as untracked. Decide: remove the inner `.git` and commit to the monorepo.
- Stray files in app root: `fix_shared_imports.py`, `update_imports*.py`, `frd.md`, several release/quiz `*.md`.
- Unused deps: `cupertino_icons`, `video_player`, `chewie`, `dio`, `hive`, `hive_flutter`, `android_alarm_manager_plus`, `hive_generator`, `build_runner`. Missing: `connectivity_plus`, `flutter_localizations`, `flutter_secure_storage` (token is in SharedPreferences), `package_info_plus`.
- Dead code: `SpeakerListScreen` → `SpeakerDetailScreen` → `ImageViewerScreen`, `SpeakerCard`, `GenderCard`, `LatestVideoCard`, `DirectusService`, five unused Home builders, unused provider/service methods (full list in mobile audit §1).
- `assets/images/` declared but empty (fresh clone can fail bundling).
- Android: `USE_EXACT_ALARM` (Play policy: alarm/calendar apps only), `USE_FULL_SCREEN_INTENT` (restricted since Android 14), unused `READ/WRITE_EXTERNAL_STORAGE`, `ACCESS_NOTIFICATION_POLICY`. iOS: camera/mic/photo usage strings with no usage (review risk), `NSAllowsArbitraryLoads=true`.
- Tests: 29 pass, but `main_navigation_footer_test.dart` and `video_reels_screen_test.dart` hit the production API; all widget tests swallow overflow errors; no coverage of auth, providers' JSON parsing, progress service, quiz scoring, storage.

---

## Suggested fix order for the implementing agent

1. **P0-1** role check (one line). Then **P0-2/P0-3** server-side grading + strip answer keys (API `quizzes.js`, `quizQuestions.js`, `videoQuestions.js`; mobile `quiz_provider.dart` stops computing). **P0-4/P0-5** progress and video-quiz locks. **P0-6/P0-7** hygiene.
2. **A2, A3, A17** (error middleware, body guard, PORT) — small, unblocks everything else.
3. **C2, C3, M1, M2, M3** together: standardise auth/user/error shapes on both sides.
4. **A6, A7, C6, C7**, then **M12–M19** (video/progress correctness).
5. **M5, M6, D1, D2, D3** (session handling on both clients).
6. **A4, A5, A19** (data integrity + indexes).
7. **C4** decide quiz list (Option B) → **M7–M11**, **D6**, **A9–A11**, delete legacy quiz routes.
8. **R1, R3, R4, R5** (course link, publish state, episode order, user progress endpoint) — these unlock the product loop in `PLAN.md`.
9. Admin IA regroup + shared components (P4/P5), mobile cleanup (P5).
