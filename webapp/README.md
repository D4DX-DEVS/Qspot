# Qspot web app

Sign-in and Quiz from the mobile app, for the browser. Same API, same rules,
same look (colours, Manrope font, artwork and wording copied from
`mobile-app/lib`). Mobile-first; it widens into a centred column on desktop.

Stack: Vite 7, React 19, React Router 7, Tailwind CSS 4, lucide-react (the
icon set the app uses). Matches `Qspot-admin`.

## Run it

```bash
cd webapp
npm install
npm run dev        # http://localhost:5173, /api goes to the live API
```

Point it at a local API instead (`.env.local`, see `.env.example`):

```bash
VITE_API_PROXY_TARGET=http://localhost:5001
```

Other scripts: `npm test` (quiz logic tests), `npm run lint`, `npm run build`.

### Settings (`.env.local`)

| Variable | What it does |
| --- | --- |
| `VITE_API_PROXY_TARGET` | Dev only: where `/api` is forwarded. Default: live API. |
| `VITE_API_BASE_URL` | Built site only: API address. Default: live API. The API's `CORS_ORIGIN` must allow the site. |
| `VITE_ENABLE_REGISTRATION` | `true` shows "Register Now" and `/register`. Off by default. |

## What is in it

- **Sign in** with name + phone number (`POST /api/user/login`), with
  the app's checks and messages. The session survives a refresh and renews
  itself when less than a day is left. An expired sign-in returns to sign-in.
- **Registration** is built but hidden (see the flag above).
- **Quiz list**: live, upcoming and ended quizzes, scores, answers waiting to
  be sent, refused answers, and "Continue" cards when offline.
- **Taking a quiz**: language locked at the start, every tap saved in the
  browser, whole-quiz / per-question / closing-time countdowns that keep
  running across refreshes, automatic submit when time is up. A refresh
  reopens the quiz where the student was. If the connection drops, the
  answers stay saved and are sent when the connection is back.
- **Results and review**: scores straight from the server (never worked out
  in the browser), answer review once the server releases the answers.
- **Certificate**: shown when the admin has issued one, like the app. Preview,
  Download PDF and Print (the print layout is the admin panel's).

## Layout

```
src/
  config/      API address and feature flags
  lib/         ChangeNotifier store base + hooks (the app's Provider pattern)
  services/    API client, storage, sign-in renewal
  stores/      toasts and dialogs
  components/  shared UI (one component per file)
  theme/       artwork palette, accent tones (page colours live in index.css)
  features/
    auth/         sign-in, registration, logout, canvas artwork
    quiz/         models, offline store, submission, stores, pages
    certificate/  model, PDF/print, pages
```

Logic sits in stores and action files; pages only draw. Each file names the
mobile file it was ported from.

## Not in the web app

Quiz reminder notifications and push (phone-only), the faculty screens, and
every other app tab. Two tabs open on the same quiz are not coordinated.
