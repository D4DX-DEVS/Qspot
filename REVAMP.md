# QSPOT — Revamp: Current State, Gaps, and Backlog

**Status doc** · 2026-09-19 · companion to `PLAN.md`

This file describes what QSPOT actually is in this repository today, how far it is
from the vision in `PLAN.md`, the API contract drift that has already been patched,
the one product decision that gates the next phase, a phased backlog, and the new
brand palette.

Scope note: everything here was read from the working tree. Where production state
cannot be known from code (for example whether the legacy untitled quiz document
still exists in the live database), it is called out as unknown instead of guessed.

---

## 1. What QSPOT is today

QSPOT today is a **content + quiz companion app for a Quran learning programme**,
not the teen practice-loop platform described in `PLAN.md`. It ships as three
separate codebases in one repository:

| Part | Stack | Root |
|---|---|---|
| Mobile app | Flutter (Android/iOS/web/desktop targets) | `mobile-app/` |
| Admin panel | React + Vite + Tailwind + axios | `Qspot-admin/` |
| API | Express 5 + MongoDB (Mongoose), DigitalOcean Spaces CDN | `Qspot-API/` |

### 1.1 User flow (mobile)

1. **Splash** — `mobile-app/lib/screens/common/screens/splash_screen.dart` waits
   3 s, calls `AuthProvider.initialize()`, then routes to `MainNavigationScreen`
   if a saved user exists, otherwise `LoginScreen`.
2. **Sign-up / sign-in** — `mobile-app/lib/screens/auth/screens/login_screen.dart`
   and `registration_screen.dart`. Sign-in is phone + WhatsApp OTP; registration
   collects **name, phone, class** only. OTP is sent by Dxing
   (`Qspot-API/services/otpWhatsapp.js`); on verify the API returns a 24 h JWT
   which the app stores in `SharedPreferences` (`AuthService`, key `auth_token`).
   `TEST_LOGIN`/`TEST_OTP` in `Qspot-API/.env` bypass real OTP for development.
   Registration does **not** issue a token; the user is sent back to log in.
3. **Main navigation** — `main_navigation_screen.dart`: bottom tabs
   **Home · Videos · Subjects · Schedule · Quiz · Ask Question**. The Quiz tab is
   conditional on `quizProvider.isQuizEnabled`, i.e. the fetched quiz config's
   `isEnable` flag (`mobile-app/lib/screens/quiz/provider/quiz_provider.dart`).
4. **Home** — `home_screen.dart`: latest video, recent videos, subjects,
   faculties (speakers), and a banner carousel. App bar has search, notifications,
   bookmarks, settings.
5. **Videos / Subjects / Speakers** — list + detail screens; videos play via
   `video_player`/`chewie`/`youtube_player_flutter`; bookmarks are stored locally
   (Hive/sqflite), not server-side.
6. **Schedule** — `schedule_screen.dart` lists schedules grouped by date and
   registers local notifications/alarms via
   `mobile-app/lib/screens/schedule/service/alarm_service.dart`
   (`flutter_local_notifications`, `android_alarm_manager_plus`).
7. **Quiz** — `mobile-app/lib/screens/quiz/screens/`:
   `quiz_screen.dart` (config/status card + language picker English/മലയാളം),
   `quiz_question_screen.dart` (progress bar, one question per page, locale
   toggle), `quiz_results_screen.dart`, `quiz_review_screen.dart`. On submit the
   provider posts the attempt and also saves it locally (sqflite,
   `mobile-app/lib/services/quiz_storage_service.dart`).
8. **Ask Question** — `ask_question_screen.dart` and
   `speaker_detail_screen.dart` post to `POST /api/questions` (student asks a
   faculty member). `my_questions_screen.dart` lists the user's own questions.
9. **Settings** — `settings_screen.dart`: About Us, Contact Us, Ask a Question,
   My Questions, Feedback, Privacy Policy (all link out to `https://d4dx.co/...`),
   Logout.

Content of the quiz is inconsistent today: the Quiz start screen is hardcoded to
"Indian freedom struggle" (`quiz_screen.dart`) and the bundled fallback questions
in `mobile-app/assets/json/quiz_questions.json` are Indian-history questions,
while the seeded API quiz content (`Qspot-API/scripts/seed-demo.js`) is Quran
questions. See §3 for why the app may be showing the bundled set.

### 1.2 Data model (`Qspot-API/models/`)

| Model | File | Fields (abridged) | Notes |
|---|---|---|---|
| `user` | `models/user.js` | name, phone, email, class | No password, no role, no age/DOB. OTP only. |
| `speaker` | `models/speakers.js` | name, designation, image, imageKey, order | "Faculty" in the app/UI. |
| `subject` | `models/subject.js` | order, name, image, imageKey | |
| `video` | `models/videos.js` | title, description, video, videoKey, subject, releaseDate | |
| `schedule` | `models/schedule.js` | class, scheduleDate, faculty, title | |
| `banner` | `models/banner.js` | image, imageKey | |
| `notification` | `models/notification.js` | title, description | One-way announcements. |
| `question` | `models/question.js` | description, faculty, subject, user, answer, answeredBy, answeredAt | Student→faculty Q&A. Not peer discussion. |
| `quizConfig` | `models/quizConfig.js` | title (nullable), startDate, endDate, numberOfQuestions, questionsRandomization, isEnable, overallTimeLimit, perQuestionTimeLimit, optionsCount | **This is the quiz definition**, despite the name. `title` is null for the legacy single quiz. |
| `QuizQuestion` | `models/quizQuestions.js` | quizId (nullable), type, question_en/ml, options_en/ml (JSON strings), correct_answer (English option **text**), difficulty | |
| `quiz` | `models/quiz.js` | userId, quizId, language, questions[], answers[], totalDuration, score, percentage | **This is an attempt**, not a definition. `quizId` refs `quizConfig`. |

There is **no** XP, streak, mastery, badge, pod, or progress-gap model. The only
per-user learning record is the quiz attempt.

### 1.3 API endpoints (`Qspot-API/server.js`)

Base mounts:

| Mount | File | Notable routes |
|---|---|---|
| `/api/admin` | `routes/admin.js` | `POST /login` (env creds, JWT role `admin`); CRUD `/users` |
| `/api/user` | `routes/users.js` | `POST /register`, `POST /login/request-otp`, `POST /login/verify`, `GET /my-questions`, `GET /my-questions/:id` |
| `/api/videos` | `routes/videos.js` | public list/detail; admin CRUD with upload |
| `/api/subjects` | `routes/subjects.js` | public list/detail; admin CRUD with upload |
| `/api/speakers` | `routes/speakers.js` | public list/detail; admin CRUD with upload |
| `/api/schedules` | `routes/schedules.js` | public list/detail/by-faculty; admin CRUD |
| `/api/banner` | `routes/banner.js` | public list/detail; admin CRUD with upload |
| `/api/notifications` | `routes/notifications.js` | public list/detail; admin CRUD |
| `/api/questions` | `routes/questions.js` | public list/detail (answers hidden), `POST` (auth user), `PUT`/`DELETE` own, admin answer `POST, PUT, DELETE /:id/answer`, `GET /admin/:id` |
| `/api/quizzes` | `routes/quizzes.js` | `GET /config` (public), `POST, PUT, DELETE /config` (admin), `POST /attempt` (user), admin `GET, DELETE /attempt/:attemptId`, `GET /stats` |
| `/api/quiz-questions` | `routes/quizQuestions.js` | `GET /` (dual-shaped, see §3), `GET, POST, PUT, DELETE` (admin) |
| `/api/quiz-definitions` | `routes/quizDefinitions.js` | admin CRUD quizzes; `GET /:id/questions`, `GET /:id/results` |
| `/api/user-quizzes` | `routes/userQuizzes.js` | public `GET /`, `GET /:id`, `GET /:id/questions` — the multi-quiz read API, **not used by the app** |

Admin auth is `authenticateToken` (JWT, role `admin`); app auth is
`authenticateUser` (JWT, user must still exist). Both in
`Qspot-API/middlewares/auth.js`.

### 1.4 Admin panel (React)

Routes registered in `Qspot-admin/src/App.jsx`; navigation in
`src/components/Sidebar.jsx`: Users, Speakers, Subjects, Questions, Quizzes,
Quiz Attempts, Schedules, Videos, Notifications, Banner.

- `AdminDashboard.jsx` = **Users** (search, edit, delete).
- `QuizzesPage.jsx` = list/create/edit/delete quizzes via `/api/quiz-definitions`;
  the legacy untitled quiz is marked and cannot be renamed/deleted.
- `QuizPage.jsx` = per-quiz question manager (query param `?quizId=`) plus a
  legacy `POST/PUT/DELETE /api/quizzes/config` editor.
- `QuizAttemptsPage.jsx` = all-results leaderboard (`GET /api/quizzes/stats`) or
  per-quiz results (`GET /api/quiz-definitions/:id/results`), with score/time
  ranking; `QuizAttemptDetailPage.jsx` shows one attempt.
- `QuestionsPage.jsx` = student Q&A moderation and faculty answers.

### 1.5 Facts that matter for the revamp

- **Scoring is client-computed.** `POST /api/quizzes/attempt` trusts the app's
  `score`, `percentage`, `answers[].isCorrect`, and even the echoed
  `questions[].correctAnswer`. The server only validates shape and counts
  (`routes/quizzes.js`).
- **One attempt per user per quiz** is enforced by looking up
  `Quiz.findOne({ userId, quizId })` in `routes/quizzes.js`.
- **Quiz selection is stateless.** `GET /api/user-quizzes/:id/questions` picks a
  random subset per call and notes in-code that repeats are not guaranteed to
  match; the attempt record does not store which question IDs were shown.
- `mobile-app/lib/screens/quiz/widgets/gender_card.dart` is defined but never
  referenced anywhere in `lib/` — dead code.

---

## 2. Gap analysis vs `PLAN.md`

Each row is one idea from the plan. "Today" is what is actually in this repo.

| Idea (PLAN.md) | What exists today | Gap | Cheapest path to close it |
|---|---|---|---|
| **Daily loop** (`PLAN.md` §5: warm-up → curiosity → focus practice → peer → wrap, 10–15 min) | Single quiz tab with a start screen, N questions from one config, results. No "Today" screen, no warm-up, no wrap, no daily trigger. | The core retention mechanic does not exist at all. | Client-first: one "Today" screen that composes existing questions + the streak counter below, using the quiz data already fetched. Keep it local (`shared_preferences`/Hive already in `pubspec.yaml`) so no API change is needed. Server-side `daily_quests` only when cross-device sync matters. |
| **XP / streaks / badges** (`PLAN.md` §6) | Nothing. Attempts store score/percentage; there is no XP counter, streak, grace day, coin, or badge anywhere in `mobile-app/`, `Qspot-API/models/`, or the admin. | No progress currency, no habit signal. | Local-only XP/streak keyed by date in `SharedPreferences` (already the app's storage pattern), computed on quiz submit. Derive a first badge set from quiz results. Server-side XP needs a new `xp_events` collection. |
| **Peer learning / social** (`PLAN.md` §7: doubt wall, teach-back, pods, duels) | A one-way **student→faculty** Q&A only (`models/question.js`, `routes/questions.js`, `ask_question_screen.dart`, `QuestionsPage.jsx`). No peer answers, no pods, no duels, no teach-back. | The plan's biggest differentiator is absent. | Reuse `question` as a class-scoped doubt wall (add a reply collection + class filter) and ship read/answer UI before building pods or duels. Needs a class field on users, which `models/user.js` already stores as `class`. |
| **Mastery analytics** (`PLAN.md` §8: topic mastery, error type, confidence, pace; student/teacher/parent dashboards) | Admin leaderboard by score and time (`routes/quizDefinitions.js` `/:id/results`, `routes/quizzes.js` `/stats`). Per-attempt detail in `QuizAttemptDetailPage.jsx`. Nothing per-topic, no decay, no confidence, no parent/teacher view. | Marks-level reporting only; no mastery model. | Read-only aggregation endpoint over existing attempts (group `answers.isCorrect` by question `difficulty`/topic) plus a student-facing summary on `quiz_results_screen.dart`. No new collection needed for v1. |
| **Adaptive practice** (`PLAN.md` §5 step 3, §10 Phase 3) | `questionsRandomization` shuffle in `routes/userQuizzes.js` and client-side shuffle in `quiz_provider.dart`. No difficulty targeting, no re-serving of wrong answers, no ability estimate. | Selection is random, not adaptive. | Serve the user's previously-wrong questions first by joining attempt history in `routes/userQuizzes.js`; defer item-response modelling. |
| **Curiosity content** (`PLAN.md` §5 step 2) | `notification` model + `NotificationsPage.jsx` + `notifications_screen.dart` for announcements. | No daily-out-of-syllabus hook, no peer answer distribution. | Reuse the notification model for a "daily question" document plus a small home widget; add a poll only after it shows engagement. |
| **Safety / moderation** (`PLAN.md` §12: profanity filter, report/block, teacher queue, DPDP parental consent, data minimisation) | Token-gated posting. `PUT`/`DELETE /api/questions/:id` checks ownership. No profanity filter, no report/block, no moderation queue, no consent flow, no age field. | Written content is effectively unmoderated, and there is no verifiable parental consent for minors. | Add a report flag + `status` to `models/question.js` and a review tab in `QuestionsPage.jsx`; add a text filter on `POST /api/questions`. Treat parental consent as a separate, explicitly-scoped workstream. |

Two plan-level gaps are cross-cutting and worth naming separately:

- **Stack divergence.** `PLAN.md` §11 specifies Next.js PWA + Supabase/Postgres +
  RLS. The build is Flutter + Express + MongoDB with no row-level security. The
  plan's security model ("class-scoped access enforced in the database") is not
  available as described; class scoping would have to be enforced in the API.
- **No server-side identity for minors.** `models/user.js` has name/phone/class
  and no age or consent record, so the DPDP requirement in `PLAN.md` §12 cannot
  be satisfied without schema and flow changes.

Cannot be determined from the code: whether the legacy untitled `quizConfig`
document still exists in the production database, and therefore whether the
app's quiz is currently driven by it or by a titled quiz. See §3.

---

## 3. Known contract drift (already patched)

### What changed

The shipped Flutter app was written against a **single-quiz** API. Three
contracts then changed when multi-quiz support landed (commit `d0b80be`,
"Add multi-quiz support across API and admin panel"):

1. **`GET /api/quizzes/config`** used to return the one untitled `quizConfig`
   document. After the migration, quizzes created in the admin all have titles,
   so a lookup filtered on "untitled" finds nothing and the app loses its config.
2. **`POST /api/quizzes/attempt`** resolved the config the same way, so an
   attempt without a `quizId` (which is how the app submits) failed to find a
   config.
3. **`GET /api/quiz-questions`** used to return a **bare JSON array** of
   questions; the newer API returns `{ items, total, page, limit }` for the admin
   listing. The app parses the body directly as a `List`.

### The patch

- `Qspot-API/services/quizConfigResolver.js` — `resolveActiveConfig()` prefers
  the legacy untitled config, else the quiz that is live now (enabled and inside
  its date window), else the most recently started enabled quiz.
- `Qspot-API/routes/quizzes.js` — `GET /config`, `POST /attempt`, and
  `GET /stats` use the resolver. `POST /attempt` now also stamps the resolved
  `quizId` onto the attempt so admin listings can link it.
- `Qspot-API/routes/quizQuestions.js` — non-admin callers get the original bare
  array scoped to the active config; admin callers keep the paginated
  `{ items, total, page }` shape.

These three edits plus `quizConfigResolver.js` are **uncommitted** in the working
tree (`git status`: `M Qspot-API/routes/quizQuestions.js`,
`M Qspot-API/routes/quizzes.js`, `?? Qspot-API/services/quizConfigResolver.js`).

### Why it matters that the already-installed app keeps working

Mobile binaries are installed once and updated on the user's schedule, not the
server's. An already-installed app cannot be changed by a deploy, so the server
must keep serving the old contract indefinitely or the app breaks for users who
have not updated — potentially for months, and with no error the user can act on.

The failure mode is silent and total: the Quiz tab is rendered only when
`config.isEnable` is true (`main_navigation_screen.dart`), and
`fetchQuizConfig()` swallows non-200 responses
(`quiz_provider.dart`). A `404` from `GET /config` therefore makes the whole Quiz
tab disappear rather than showing an error, and no attempt can be submitted
because `POST /attempt` would also `404`. The resolver is what prevents the
multi-quiz migration from turning into a silent feature removal for the installed
base. The same reasoning applies to the question-array shape: a `{items,...}`
body parsed as a `List` throws inside `_loadQuestionsFromAPI()` and is caught,
dropping the app to an empty list.

### Caveats found while reading the code

These are observations, not confirmed live behaviour:

1. **Auth header on the questions call.** `GET /api/quiz-questions` is behind
   `authenticateToken` (`routes/quizQuestions.js`), but
   `QuizProvider._loadQuestionsFromAPI()` in `quiz_provider.dart` sends only
   `Content-Type`. On a `401` the provider falls back to the bundled
   `assets/json/quiz_questions.json`. If that is what production does, the
   question-array compatibility branch is never reached by the app, and the
   quiz the user sees is the bundled Indian-history set regardless of what the
   admin configured. This needs one check against the live API; it cannot be
   settled from the repository alone.
2. **`correct_answer` type mismatch.** `models/quizQuestions.js` stores
   `correct_answer` as the English option **text**, while the app's
   `QuizQuestion.correctAnswer` is an option **index** (`quiz_model.dart`) and
   `_parseCorrectAnswer()` does `int.tryParse(...) ?? 0`. Text answers collapse
   to index `0`; numeric answers such as `"114"` become index `114`, which is out
   of range. So even after the shape patch, scoring is only correct for the
   bundled asset, not for API-sourced questions.
3. **Legacy-first preference has a side effect.** Because
   `resolveActiveConfig()` checks the untitled config first, if that document
   still exists and is enabled, the app will keep showing the legacy quiz and
   will never see any quiz created in the admin. That is the intended safety net
   for the installed app, but it also means new quizzes cannot reach the app
   until the app moves to a quiz list (§4, Option B).

---

## 4. Product decision needed: one live quiz, or a quiz list in the app?

The admin can now manage many quizzes, but the app still shows exactly one
(one config plus its questions). Two ways forward:

### Option A — keep one live quiz

The app keeps a single active quiz; the admin's multi-quiz capability is
effectively one-at-a-time.

- **What it needs:** keep exactly one enabled, in-window quiz; decide the fate of
  the legacy untitled document. Note the hard constraints: `resolveActiveConfig()`
  prefers the legacy doc, and `routes/quizDefinitions.js` refuses to rename or
  delete the legacy quiz. So "the one live quiz" is effectively "the legacy quiz"
  until the resolver order changes or the legacy doc is removed from the database.
  Admin UI should make the singled-out quiz obvious (it already flags the legacy
  one in `QuizzesPage.jsx`).
- **Cost:** no mobile release, no client work.
- **Trade-off:** the multi-quiz admin work (commit `d0b80be`) is largely unused;
  running a weekly series, a Ramadan quiz, or per-class quizzes is not possible
  without shadowing. Every new quiz risks being invisible.

### Option B — quiz list in the app

The Quiz tab shows the available quizzes; the user picks one.

- **What it needs (much of it already exists):**
  - API: `GET /api/user-quizzes` (list), `GET /api/user-quizzes/:id`,
    `GET /api/user-quizzes/:id/questions` are already implemented in
    `routes/userQuizzes.js`, are public, and already exclude the legacy untitled
    quiz via `NON_LEGACY_FILTER`.
  - Attempts: `POST /api/quizzes/attempt` already accepts an optional `quizId`
    and scopes the once-per-user check by it.
  - Mobile: new quiz-list model/provider/screen; pass `quizId` into
    `submitQuizAttempt()`; add a list entry point under the Quiz tab. The tab's
    visibility rule (`isQuizEnabled`) needs to become "any available quiz".
  - Release: an app-store build and staged rollout; decide the fate of the
    bundled JSON fallback and of the legacy config path.
- **Cost:** one mobile release cycle plus client work.
- **Trade-off:** unlocks the multi-quiz product, but the app and API must be
  maintained in both shapes during the transition window.

**Recommendation to settle:** Option B is the destination — the API half is
already written, so the remaining cost is client + release — and Option A is
only a short bridge if a new app build cannot ship soon. This is a decision for
the product owner, not something the code can resolve.

---

## 5. Phased revamp backlog

Ordered by value per effort within each phase. Effort: S = days, M = 1–2 weeks,
L = multi-week. Risk is implementation/regression risk.

### Phase 1 — make the quiz correct and trustworthy

| # | Item | Why it matters | Files that change | Effort | Risk |
|---|---|---|---|---|---|
| 1 | **Fix the app's question fetch** — attach the bearer token to `GET /api/quiz-questions`, or expose the legacy array publicly. | Decides whether the app shows admin-configured questions or the bundled set. Until this is settled, nothing else about content is trustworthy. | `mobile-app/lib/screens/quiz/provider/quiz_provider.dart`; `Qspot-API/routes/quizQuestions.js` | S | M (auth/security choice) |
| 2 | **Fix `correct_answer` mapping** — resolve the stored option text to an index instead of `int.tryParse`. | API-sourced quizzes currently score wrong (text→0, numeric→out of range). | `mobile-app/lib/screens/quiz/provider/quiz_provider.dart`, `mobile-app/lib/screens/quiz/model/quiz_model.dart` | S | M |
| 3 | **Resolve quiz content/fallback** — make the bundled JSON and the API quiz agree, or drop the fallback. | The app is hardcoded to "Indian freedom struggle" while the seed content is Quran; this is a visible content error. | `mobile-app/assets/json/quiz_questions.json`, `mobile-app/lib/screens/quiz/screens/quiz_screen.dart`, `quiz_provider.dart` | S | L |
| 4 | **Decide and codify the single source of "live quiz"** — retire or demote the legacy-first preference once Option B ships. | Legacy-first currently hides every admin-created quiz from the app. | `Qspot-API/services/quizConfigResolver.js`, `Qspot-API/routes/quizzes.js` | S | H (breaks installed app if done first) |
| 5 | **Server-side scoring** — recompute `score`/`percentage` from `quizId` + question bank instead of trusting the client. | The API currently accepts self-reported scores and echoed correct answers, so leaderboards are trivially spoofable. | `Qspot-API/routes/quizzes.js`, `Qspot-API/models/quiz.js` | M | M |
| 6 | **Commit the compatibility patch** — the resolver and route edits are uncommitted, so they can be lost. | The fix that keeps installed apps working is not yet in version control. | `Qspot-API/routes/quizQuestions.js`, `Qspot-API/routes/quizzes.js`, `Qspot-API/services/quizConfigResolver.js` | S | L |

### Phase 2 — quiz list, then the daily loop

| # | Item | Why it matters | Files that change | Effort | Risk |
|---|---|---|---|---|---|
| 7 | **Quiz list in the app (Option B)** | Unlocks multi-quiz, weekly series, and event quizzes; makes the admin work usable. API already exists. | `mobile-app/lib/screens/quiz/` (new model/provider/list screen), `mobile-app/lib/utils/api_urls.dart`, `main_navigation_screen.dart` | M | M |
| 8 | **Daily loop screen ("Today")** | The plan's core retention mechanic; gives the user one reason to return tomorrow. | new screen/provider in `mobile-app/lib/screens/`, `main_navigation_screen.dart`, `home_screen.dart` | M | M |
| 9 | **Local XP + streak (+ grace day)** | Builds the habit loop without backend work; matches the plan's guardrail against punishing streak loss. | new service in `mobile-app/lib/services/`, `quiz_provider.dart`, results screen | S | L |
| 10 | **Mastery read-out** | Starts the transition from marks to mastery using data already stored in attempts. | new read-only API route (aggregate over `models/quiz.js`), `quiz_results_screen.dart` | M | L |
| 11 | **Daily curiosity question** | Cheap delight hook; reuses an existing model and admin flow. | `Qspot-API/models/`, `routes/`, `Qspot-admin/src/pages/`, `home_screen.dart` | S | L |

### Phase 3 — social, intelligence, safety

| # | Item | Why it matters | Files that change | Effort | Risk |
|---|---|---|---|---|---|
| 12 | **Doubt wall (peer answers)** | The plan's biggest differentiator; turns Q&A into peer learning. | `Qspot-API/models/question.js`, `routes/questions.js`, `mobile-app/lib/screens/question/`, `Qspot-admin/src/pages/QuestionsPage.jsx` | L | H (moderation) |
| 13 | **Moderation + reporting + parental consent** | Required for a minors' product; currently absent (profanity, report/block, consent, age). | `Qspot-API/models/user.js`, `models/question.js`, `routes/questions.js`, `Qspot-admin/src/pages/QuestionsPage.jsx` | M–L | H (legal/compliance) |
| 14 | **Badges + spaced repetition / mastery decay** | Extends the habit loop into durable learning; needs new models. | new `Qspot-API/models/`, new routes, `mobile-app` screens | L | M |
| 15 | **Adaptive difficulty** | Personalises practice beyond random selection. | `Qspot-API/routes/userQuizzes.js`, models, mobile practice screen | L | M |
| 16 | **Teacher / parent views** | The plan's distribution and trust layer; needs class grouping that the API does not yet expose. | `Qspot-API/routes/`, `Qspot-admin/src/pages/` | L | M |

Sequencing notes:

- Items 1–3 are prerequisites for any claim that the app shows the right quiz;
  item 6 (committing the patch) is trivial and should not wait.
- Item 7 should precede serious daily-loop work, because the daily loop needs
  more than one quiz to draw from.
- Item 4 is deliberately last in Phase 1: changing the resolver order before the
  app supports a list is the one change that can break every installed user.

---

## 6. Theme direction

QSPOT is moving to a **light brand**. The Flutter app is being re-skinned to:

| Role | Value | Usage |
|---|---|---|
| Background | `#FFFFFF` white | Page and surface background. |
| Primary | `#7A2048` | Brand colour: headers, primary buttons, active states, key text. |
| Accent — coral | `#E8836A` | Small highlights only (badges, progress, selected markers). |
| Accent — amber | `#E9A768` | Small highlights only (awards, streaks, secondary markers). |

The accents are highlights, not fills: do not build coral or amber backgrounds,
banners, or large panels from them.

Where this lands in code:

- `mobile-app/lib/themes/app_theme.dart` is currently a **dark** theme
  (`backgroundColor = #000000`, gradient `#4A1A4A` → `#8B1538`, `darkTheme`).
  Re-skinning means a light theme with the palette above, not a recolour of the
  existing dark constants.
- `mobile-app/lib/main.dart` selects `AppTheme.darkTheme`; that reference changes.
- Screens use `AppTheme.*` constants heavily and also hardcode colours
  (`quiz_review_screen.dart` uses `#1A3A2E`/`#3A1A1A`; `quiz_screen.dart` uses
  `Colors.green/orange/red` status tints). Those need a pass so the light theme
  stays readable.
- Splash/launcher colours are separate: `mobile-app/pubspec.yaml`
  (`flutter_native_splash.color: "#0F1419"`, launcher `background_color`/
  `theme_color`).
- The admin already uses `#701845` and `#EFB078` gradients
  (`Qspot-admin/src/components/Sidebar.jsx`). Those are close to, but not the
  same as, the new brand values; reconcile admin and app to one palette so the
  two surfaces read as one product.

Open question for brand: whether the logo assets (`assets/icons/Logo 01.png`,
`Icon.png`) are also being updated. The palette change alone will leave the
existing dark-background splash and launcher art looking mismatched on a white
app.
