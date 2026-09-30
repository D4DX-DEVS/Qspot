# QSpot Admin

Admin panel for QSpot: courses, subjects, videos (with per-episode content
and questions), speakers, schedules, quizzes, student Q&A, banner and
notifications. React 19 + Vite + Tailwind 4.

## Getting started

```bash
npm install
cp .env.example .env   # set VITE_API_BASE_URL to your Qspot-API instance
npm run dev
```

## Scripts

- `npm run dev` — start the Vite dev server
- `npm run build` — production build
- `npm run preview` — preview the production build locally
- `npm run lint` — run ESLint

## Structure

- `src/api/client.js` — the single axios instance every page uses. Attaches
  the admin token, redirects to `/admin/login` on 401/403, and normalises
  API error messages onto `error.message`.
- `src/auth/RequireAuth.jsx` — route guard used by every protected route in
  `src/App.jsx`.
- `src/components/ui/` — shared building blocks (`Modal`, `PageHeader`,
  `Pagination`, `Spinner`, `ErrorState`, `EmptyState`, `EntitySelect`
  (`FacultySelect`/`SubjectSelect`/`CourseSelect`), `DateTimePicker`).
- `src/hooks/` — `useBodyScrollLock`, `usePageTitle`.
- `src/utils/format.js` — `formatDuration`, ISO/local datetime helpers.
- `src/pages/` — one file per admin page, grouped in the sidebar as
  Content (Courses, Subjects, Videos), Learners (Users, Speakers, Q&A,
  Schedules), Quizzes (Quizzes, Attempts) and App (Banner, Notifications).
  Video content (questions/learn note/downloads) and a subject's chapter
  guide are reached via cross-links rather than the sidebar.

## Backend contract

This app talks to `Qspot-API`. See that repo's `CONTRACT.md` for the exact
request/response shapes it expects.
