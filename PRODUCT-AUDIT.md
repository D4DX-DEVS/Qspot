# QSPOT Product Audit and Teen Learning Roadmap

Audit date: 2026-09-23

Scope: local Flutter learner app, React admin panel, and Express/Mongo API.
Primary users are teenage learners; secondary users are teachers, moderators,
and content administrators.

## Executive Summary

QSPOT already has a useful lesson spine: course-aware subjects, ordered videos,
study notes, handouts, server-backed watch progress, completion-gated video
questions, quizzes, faculty Q&A, schedules, bookmarks, and admin CRUD. The
current experience still behaves like a content catalogue. The first screen
does not answer "what should I do next?", and the admin workflow is split across
flat entity pages instead of one curriculum workspace.

The recommended direction is evolutionary:

1. Add a learner **Today** layer that prioritises due work, upcoming live work,
   unfinished lessons, and ready practice in that order.
2. Make **Curriculum** the admin source of truth for Course -> Subject -> Video,
   while keeping existing deep-link pages working.
3. Continue the delivered operations layer with binary uploads, richer exports,
   and production longitudinal analytics.
4. Delay peer features, public leaderboards, and social discovery until class
   membership, moderation, age/consent, and privacy controls are real.

## Evidence and Limitations

| ID | Class | Evidence | Status |
|---|---|---|---|
| EV-S01 | Screenshot | Mobile Home shows greeting, recent-video poster grid, quick access, and bottom navigation | Tool-verified |
| EV-S02 | Screenshot | Mobile Subjects shows image-heavy cards with weak visible progress context | Tool-verified |
| EV-S03 | Screenshot | Mobile Videos shows a catalogue grid with bookmark icons and relative dates | Tool-verified |
| EV-S04 | Screenshot | Mobile More sheet contains Schedule, Quiz, Ask Question, Faculties, My Questions, Bookmarks, Notifications, Settings | Tool-verified |
| EV-S05 | Screenshot | Admin Users is a dense dark table with search and edit/delete actions | Tool-verified |
| EV-S06 | Screenshot | Admin Courses is empty in the current data set while other content exists | Tool-verified |
| EV-S07 | Screenshot | Admin Videos resolves from loading to 48 videos and exposes Content, Stats, Edit, Delete per card | Tool-verified |
| EV-C01 | Code | `home_screen.dart` renders greeting, search, recent videos, quick access, courses, then banners | Observed |
| EV-C02 | Code | `VideoProvider` and `video_progress_service.dart` expose account-level progress, resume position, completion, question count, and quiz-attempt state | Observed |
| EV-C03 | Code | `routes/videoProgress.js` uses a server heartbeat and 90% watched threshold | Observed |
| EV-C04 | Code | `routes/userVideoQuiz.js` grades video questions on the server after completion | Observed |
| EV-C05 | Code | Admin has Courses, Subjects, Videos, Video Content, Chapter Guide, Users, Questions, Quizzes, and Attempts, but no canonical tree | Observed |
| EV-C06 | Code | Assignment/submission routes and an embedded, idempotent learning-event ledger now back due work, submissions, streaks, and XP | Observed |
| EV-C07 | Code | `/api/user/progress` and `/api/admin/users/:id/activity` already provide useful summary and activity primitives | Observed |
| EV-U01 | User brief | The user wants upcoming work first, notes, practical exams, video questions, Q&A, completion status, streaks, assignments/uploads, teacher visibility, and simple teen-friendly UX | User-provided |

Limitations: this is a code and local-browser audit, not a longitudinal usage
study. Keyboard behavior, real-device performance, accessibility at large text
sizes, offline recovery, and production analytics remain to be validated.

## Current Task Flow

### Learner

Entry -> OTP login -> Home -> browse recent videos/subjects -> open lesson ->
watch and resume -> server marks completion -> answer video questions -> browse
quiz/Q&A/schedule through separate destinations.

The lesson completion loop remains the strongest existing flow. Today/Next Up now
provides the ranked handoff before and after a lesson, with assignment due work,
practice readiness, and a visible habit/progress summary.

### Admin

Login -> flat entity page -> search/filter -> edit individual entity -> deep-link
to video content/stats or chapter guide.

The canonical Curriculum workspace and Learning Analytics roster now bridge the
hierarchy. A teacher can scan a curriculum tree and answer "who has not
watched/read/submitted this item?" with class and content filters.

## Strengths to Preserve

- Server-owned video progress with anti-seek heartbeats and explicit completion.
- Completion -> practice handoff after a video.
- Course grouping and subject ordering already present in the mobile client.
- Per-video notes, learn points, downloads, and question management.
- Shared admin loading, empty, error, retry, and pagination primitives.
- Calm learner palette, clear status colors, and a compact bottom navigation.
- Malayalam content already present in the data; continue the language work rather
  than replacing it with English-only copy.

## Category Scorecard

| Category | Score | Confidence | Coverage |
|---|---:|---|---|
| Existing lesson completion flow | 4/5 | High | Complete for video -> completion -> practice |
| Learner task clarity | 4/5 | High | Today/Next Up is implemented; assignments are reachable from More |
| Curriculum information architecture | 3/5 | High | Complete for course/subject/video code; partial for admin workflow |
| Progress and habit feedback | 4/5 | High | Server-owned idempotent event ledger, streaks, XP, and note-read events are implemented |
| Assessments | 4/5 | Medium | Quiz/video questions plus explicit practical exam type and server scoring |
| Assignments and submissions | 3/5 | High | Assignment lifecycle is implemented; file binary upload, due-work aggregation, and roster analytics remain |
| Teacher analytics | 4/5 | High | Class/content roster with started, completed, notes-read, practice-ready, submitted, and overdue signals |
| Accessibility and localization | 2/5 | Medium | Partial; semantics and Malayalam content exist, app-wide i18n needs work |
| Teen safety and privacy | 3/5 | High | Admin moderation, class-scoped Q&A, consent update contract, and student/admin role separation exist; parent workflow and retention controls remain |

## Prioritized Findings

### P0 — Release gates

**F-01. Protect admin and assessment truth.** Existing auth and grading hardening
is present in the working tree, but it must remain covered by route tests. Student
tokens must never reach admin routes, and answer keys/scores must stay server-owned.

**F-02. Do not ship peer/social features before safety foundations.** Add class
membership, moderation status/reporting, age/consent policy, and audit history
before peer replies, duels, or public rankings.

### P1 — First teen-learning MVP

**F-03. Home does not answer “what should I do next?”** (EV-S01, EV-C01, EV-U01) **[Delivered in Slice 1]**
Move a single Today/Next Up card above search and recent videos. Priority:
overdue assignment, live/upcoming quiz or session, in-progress lesson, ready
video practice, then short review. Show course, subject, duration, status, and
one clear action.

**F-04. Curriculum progress is hidden in browse screens.** (EV-S02, EV-C02)
Show completed/total counts, next episode, and resume state on course and subject
surfaces. Keep browse separate from the Today action so the first screen stays
focused.

**F-05. Admin IA is flat.** (EV-S05, EV-S06, EV-S07, EV-C05) **[Delivered in Slice 1]**
Add a canonical Curriculum workspace with nested children, counts, publication
state, release timing, and direct links to content/questions/stats. Preserve the
existing pages as focused editors.

**F-06. Assignment and due-work flow is missing.** (EV-C06, EV-U01) **[Delivered]**
Assignment authoring, due dates, allowed upload metadata, learner submission
state, teacher feedback, and assignment-aware Today due work are implemented.
Binary transport and a richer admin upcoming queue remain follow-ups.

**F-07. Teacher reporting cannot answer “who needs help?”** (EV-C07, EV-U01) **[Delivered]**
Add content-level learner rosters and class filters for started, completed,
notes-read, practice-ready, submitted, overdue, and unanswered-question states.

### P2 — Learning depth and retention

**F-08. Streak/XP needs a trustworthy product signal.** **[Core ledger delivered]**
Idempotent server learning events now power meaningful activity without watch-time
rewards from heartbeats. Grace-day entitlement, badge/mastery UX, and production
retention policy remain follow-ups.

**F-09. Language support is uneven.** Apply Malayalam/English preference to
navigation, Today, notes, assignments, and practice, and test translated text at
large sizes.

**F-10. Question concepts are disconnected.** **[Class scope/moderation delivered]** Keep assessment questions separate
from teacher Q&A, then add class-scoped discussion threads, accepted answers,
moderation, and helpfulness credit.

## Traceability

| Finding | Requirement | Success signal |
|---|---|---|
| F-03 | R-01: rank one next action on Home | More learners start a lesson from Home; lower time-to-first-action |
| F-04 | R-02: show course/subject completion and resume state | Learners can identify their next episode without opening multiple screens |
| F-05 | R-03: canonical admin Curriculum tree | A teacher can reach any lesson's content, questions, or stats in two steps |
| F-06 | R-04: assignment lifecycle with due status | Submitted/on-time/overdue states are visible on both sides |
| F-07 | R-05: content-level learner roster and filters | Teacher can identify learners needing help without manual exports |
| F-08 | R-06: idempotent streak events with grace day | Streak counts match activity dates across devices |
| F-09 | R-07: persisted app language | Same language preference applies across primary learner flows |
| F-10 | R-08: class-scoped moderated discussion | No public learner PII or unmoderated peer channel |

## Implementation Status (2026-09-23)

- **Delivered:** Slice 1 Today aggregate, learner Next Up card, defensive fallback, assignment-aware due work, overdue-first ranking, practical-exam metadata, admin Curriculum tree, kind-aware Today navigation, timezone-aware streak input, progress-duration fallback, and accurate Curriculum deep links.
- **Delivered:** Assignment authoring and learner submission lifecycle: published/class-scoped list and detail endpoints, text/file metadata submissions, admin grading/status review, admin Assignments workspace, and learner Assignments screen.
- **Delivered:** note-read events, content/class learner rosters, assignment-aware Today, idempotent event-ledger streak/XP, practical exam labeling/server contract, and class-scoped moderated Q&A foundations.
- **Still open:** binary upload transport, full navigation localization, parent consent workflow/retention controls, and production longitudinal analytics/export.

## Delivery Plan

### Slice 1 — Now

- `GET /api/user/today` additive aggregate over existing progress, releases,
  quizzes, and schedules.
- Learner Today/Next Up card with continue/practice-ready/upcoming status.
- Admin `/admin/curriculum` tree over current Course -> Subject -> Video data.
- Keep existing lesson completion and video-question flow intact.

### Slice 2 — Learning operations

- Assignment and submission models/routes/pages.
- Note-read events and content-level learner roster.
- Assignment-aware Today due work and teacher/class overview with scope filters.
- Remaining follow-ups: unified cross-source queue, CSV export, and binary file
  upload transport.

### Slice 3 — Retention and depth

- Server event ledger, idempotent streaks, XP, and practical/exam type are
  delivered on the existing quiz engine with server scoring.
- Remaining follow-ups: badges/mastery views, grace-day UX, app-wide
  English/Malayalam localization, and large-text validation.

### Slice 4 — Safety-gated community

- Class-scoped Q&A and admin moderation, plus a consent update contract, are
  delivered.
- Remaining follow-ups: enrollment management, threaded replies/accepted
  answers, reports/audit history, retention/deletion controls, and parent-safe
  reporting.

## Validation Checklist

- Admin route rejects a student token with 403.
- Non-admin question payloads contain no correct answer.
- Today falls back cleanly if the aggregate endpoint is unavailable.
- A completed lesson updates progress and remains completed after refresh.
- Upcoming content is labelled with an explicit date or status.
- Admin Curriculum handles loading, empty, error, and populated states.
- Flutter analyze/tests and admin build pass.
- Narrow mobile and wide admin layouts are checked after each slice.
