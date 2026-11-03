# QSPOT on Cloudflare

| Part | Was | Now |
|---|---|---|
| API | Express on DigitalOcean | Worker `qspot-api` (this folder) |
| Database | MongoDB Atlas | D1 `qspot` |
| Files | DigitalOcean Spaces | R2 `qspot-files` |
| Admin panel (`../Qspot-admin`) | Netlify | Worker `qspot-admin` (static assets) |
| Student web app (`../webapp`) | Netlify | Worker `qspot-web` (static assets) |
| Scheduled notifications | `setInterval` | Cron Trigger (every 5 min) |

The Worker runs the **existing** models/routes/services (copied unchanged into `src/app/`)
on small shims in `src/shims/` (`mongoose` over D1, `express`, `jsonwebtoken`, `multer`,
`express-rate-limit`, `axios`). Every model is a collection inside one D1 table
`docs(collection, id, data JSON)`, with expression indexes generated from the model files.
Existing Mongo `_id`s are kept, so references stay valid.

## 1. One-time setup (you run these)

```bash
cd Qspot-worker
npx wrangler login
npx wrangler d1 create qspot            # copy the printed database_id into wrangler.toml
npx wrangler r2 bucket create qspot-files
npm run migrate:remote                  # creates the tables and indexes
```

Secrets (values are in the repo-root `.env`):

```bash
npx wrangler secret put JWT_SECRET
npx wrangler secret put ADMIN_USERNAME
npx wrangler secret put ADMIN_PASSWORD
npx wrangler secret put DXING_API_KEY
npx wrangler secret put DXING_INSTANCE_ID
# only if you want the demo logins on production:
# npx wrangler secret put TEST_LOGIN ; npx wrangler secret put TEST_OTP
```

Optional: put a custom domain on the R2 bucket (dashboard > R2 > qspot-files > Settings)
and set `R2_PUBLIC_URL` in `wrangler.toml` `[vars]`. Without it the Worker serves files at `/files/<key>`.

```bash
npm run deploy                          # prints https://qspot-api.<account>.workers.dev
```

## 2. Live data

Done: the MongoDB data and Spaces files were copied into D1 and R2 and the one-off migration tools were then deleted (they were never committed).

## 3. Frontends

Each frontend is a static-assets Worker (`wrangler.jsonc` in its folder, SPA fallback on). Deployed:
- API: https://qspot-api.d4dx-fatwa.workers.dev
- Admin: https://qspot-admin.d4dx-fatwa.workers.dev
- Student web app: https://qspot-web.d4dx-fatwa.workers.dev

```bash
cd ../Qspot-admin && VITE_API_BASE_URL=https://qspot-api.d4dx-fatwa.workers.dev/api npm run build && npx wrangler deploy
cd ../webapp      && VITE_API_BASE_URL=https://qspot-api.d4dx-fatwa.workers.dev npm run build && npx wrangler deploy
```

`CORS_ORIGIN` in `wrangler.toml` lists the two frontend URLs; update it if you add custom domains.
Mobile app: rebuild with `--dart-define=API_BASE_URL=https://qspot-api.d4dx-fatwa.workers.dev`.

## 4. Local development

```bash
cp ../.env .dev.vars                    # secrets for wrangler dev (gitignored)
npm run migrate:local
node scripts/run-with-d1.mjs seed-demo.js --force   # demo data into the local D1
npm run dev                             # http://127.0.0.1:8787
node scripts/smoke.mjs                  # hits the main endpoints as admin + demo student
```

After changing a model's indexes: `npm run gen:migration`, then add the diff as a new numbered migration.

## Known limits

- Videos upload through the Worker (100 MB free / 200 MB paid request limit). Larger files need R2 multipart/presigned upload.
- Filters/aggregations the shim cannot turn into SQL scan the collection in JS (correct, slower). Add an expression index in `migrations/` if one gets slow.
- D1 has no multi-statement transactions; updates use compare-and-swap with retry so counters (`$inc`) and `$push` do not lose writes.
- The old Express/Mongo API (`Qspot-API`), `dev.sh` and the Netlify configs were removed from the repo (still in git history).
- Code still says `require('mongoose')`: that resolves to the D1 shim in `src/shims/mongoose.js`, there is no MongoDB in the runtime.
