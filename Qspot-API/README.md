# Qspot-API

Express 5 + Mongoose backend for QSPOT. Implements `CONTRACT.md` (API contract v2).

## Setup

```
npm install
cp .env.example .env   # fill in MONGODB_URI, JWT_SECRET, ADMIN_USERNAME, ADMIN_PASSWORD, ...
npm run dev             # nodemon
npm start                # node server.js
```

Seed demo data: `npm run seed` (only fills empty collections) or `npm run seed:force` (wipes and reseeds everything, including per-user progress/attempts).

Migrate a pre-contract-v2 database (titles legacy quiz, reattaches orphaned quiz questions): `npm run migrate:legacy-quiz`.

## Conventions

- Errors are always JSON `{ message }` with the proper status code (400/401/403/404/409/413/500) — never `{ ok, error }`.
- Public list endpoints return a bare JSON array. Admin paginated endpoints return `{ items, total, page, limit }`. Create/update return `{ message, <entity> }`. Delete returns `{ message, id }`.
- Auth: `Authorization: Bearer <jwt>`. Student tokens: `{ userId, phone, role: 'student' }`, 30 days. Admin tokens: `{ username, role: 'admin' }`, 24 hours.
- `options_en` / `options_ml` are JSON arrays in every response.
- `correct_answer` (quiz/video questions) is never sent to a non-admin caller.

## Endpoints

### Auth / user
- `POST /api/admin/login`
- `POST /api/user/register`
- `POST /api/user/login/request-otp`
- `POST /api/user/login/verify`
- `GET/PUT /api/user/me`
- `GET/PUT /api/user/prefs`
- `GET/PUT/DELETE /api/user/bookmarks[/:videoId]`
- `GET /api/user/progress`
- `GET /api/user/today` (authenticated learner dashboard: next item, continue/upcoming items, streak, and summary counts)
- `GET /api/user/learning-stats`, `POST /api/user/learning-stats/note-read` (server-owned streak/XP and note-read telemetry)
- `GET /api/user/assignments`, `GET /api/user/assignments/:id` (published assignments visible to the learner's class)
- `POST /api/user/assignments/:id/submit` (submit text and/or CDN file metadata; resubmission replaces the learner's own submission)
- `GET /api/user/quiz-attempts[/:id]`
- `GET /api/user/my-questions[/:id]`

### Admin users
- `GET /api/admin/users`
- `GET/PUT/DELETE /api/admin/users/:id`
- `GET /api/admin/users/:id/activity`
- `GET /api/admin/videos/:id/stats`
- `GET/POST /api/admin/assignments`, `GET/PUT/DELETE /api/admin/assignments/:id`
- `GET /api/admin/assignments/:id/submissions`, `PUT /api/admin/assignments/:id/submissions/:submissionId`
- `GET /api/admin/analytics/overview?class=&videoId=` (class/content learner roster and help signals)

### Courses / subjects / videos
- `GET/POST /api/courses`, `GET/PUT/DELETE /api/courses/:id`
- `GET/POST /api/subjects`, `GET/PUT/DELETE /api/subjects/:id`, `PUT /api/subjects/:id/guide`
- `GET/POST /api/videos`, `GET/PUT/DELETE /api/videos/:id`
- `POST /api/videos/:id/files` (handouts), `PUT /api/videos/:id/content` (learn/downloads)

### Video progress / video quiz
- `GET /api/video-progress[/:videoId]`, `POST /api/video-progress`
- `GET /api/video-questions?videoId=`, `GET /api/video-questions/counts`, `POST/PUT/DELETE /api/video-questions[/:id]` (admin)
- `GET/POST /api/user/video-quiz`

### Quizzes (Option B — quiz list in app)
- `GET /api/user-quizzes`, `GET /api/user-quizzes/:id`, `GET /api/user-quizzes/:id/questions`
- `POST /api/quizzes/attempt`
- `assessmentType: quiz|practical` is supported on quiz definitions and returned to learners.
- `GET/DELETE /api/quizzes/attempt/:attemptId` (admin)
- `GET/POST /api/quiz-definitions`, `GET/PUT/DELETE /api/quiz-definitions/:id`, `GET /api/quiz-definitions/:id/results` (admin)
- `GET/POST/PUT/DELETE /api/quiz-questions[/:id]` (admin only)

### Student Q&A
- `GET/POST /api/questions`, `GET/PUT/DELETE /api/questions/:id` (student)
- `GET /api/questions/admin`, `GET /api/questions/admin/:id`, `PUT /api/questions/admin/:id/status`, `DELETE /api/questions/admin/:id`
- `POST/PUT/DELETE /api/questions/:id/answer` (admin)

### Notifications, banners, speakers, schedules
- `GET/POST/PUT/DELETE /api/notifications[/:id]`
- `GET/POST/PUT/DELETE /api/banner[/:id]`
- `GET/POST/PUT/DELETE /api/speakers[/:id]`
- `GET/POST/PUT/DELETE /api/schedules[/:id]?class=`

Removed in this round: `GET/POST/PUT/DELETE /api/quizzes/config`, `GET /api/quizzes/stats`, `services/quizConfigResolver.js`, the public branch of `GET /api/quiz-questions`.
# Local faculty/student demo

Run the API against the local MongoDB database and seed the complete demo dataset:

```bash
MONGODB_URI='mongodb://127.0.0.1:27017/qspot' node scripts/seed-demo.js --force
MONGODB_URI='mongodb://127.0.0.1:27017/qspot' node server.js
```

The seed creates four faculty accounts (`role: faculty`) mapped to the four speaker profiles. Faculty sign in through the same OTP endpoint and receive the faculty mobile workspace token/shell.

## Lesson learning materials

In Admin > Videos > Questions, edit the plain-text Learn note and key points.
Under Learning materials, upload PDFs, images (JPEG/PNG/WEBP/GIF), or TXT files,
or add an HTTP/HTTPS file link. Uploads allow 10 files per request and 20 materials
per lesson, with images limited to 5 MB and PDF/TXT files to 25 MB by default.
Files are saved immediately; save pending note/link changes before uploading.
Students see the note, key points, image previews, and file cards in Learn.
Tapping a file opens it in the device/browser viewer; Downloads lists the same files.
This does not add offline file storage.

Uploads use DigitalOcean Spaces when configured. Development without Spaces
stores materials under uploads/handouts; production still requires Spaces.

With the local API running and local courses seeded, run:

```bash
node scripts/seed-learn-demo.js
```

This adds only `Demo - Learn materials preview` in Quran Recitation and uploads
the included real PNG, PDF, and TXT fixtures. Re-running it avoids duplicate
lessons/files. It refuses non-local databases and production mode.

Checks: `node --test tests/handout-storage.test.js` tests cloud cleanup with a
mocked storage client. `node scripts/check-learn-materials.js` exercises the local
API and deletes its temporary lesson. Production Spaces/CDN must permit CORS
image fetching from the deployed student app origin; the local preview check
does not verify deployed CDN headers.
