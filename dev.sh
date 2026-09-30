#!/bin/zsh
# QSPOT local dev — one command for everything.
#
#   ./dev.sh start     start MongoDB check + API + admin + mobile web app
#   ./dev.sh stop      stop API, admin and mobile web app
#   ./dev.sh status    what is listening on which port
#   ./dev.sh seed      wipe the demo data and load it again
#   ./dev.sh urls      print the URLs and logins
#   ./dev.sh mobile    rebuild the Flutter web build
#
# The API and the admin need Node 22 — the admin's Vite 7 will not run on Node 18.

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
NODE22=/opt/homebrew/opt/node@22/bin
API="$ROOT/Qspot-API"
ADMIN="$ROOT/Qspot-admin"
MOBILE="$ROOT/mobile-app"

job() { launchctl submit -l "$1" -- /bin/zsh -lc "$2"; }

start_api() {
  launchctl remove qspot-api 2>/dev/null || true
  job qspot-api "cd $API && exec $NODE22/node server.js >> /tmp/qspot-api.log 2>&1"
}

start_admin() {
  launchctl remove qspot-admin 2>/dev/null || true
  job qspot-admin "cd $ADMIN && exec $NODE22/node node_modules/vite/bin/vite.js >> /tmp/qspot-admin.log 2>&1"
}

start_mobile() {
  launchctl remove qspot-mobile 2>/dev/null || true
  job qspot-mobile "exec $NODE22/node $ROOT/tools/static-server.mjs $MOBILE/build/web 8090 >> /tmp/qspot-mobile.log 2>&1"
}

status() {
  for p in 27017 5001 5173 8090; do
    who=$(lsof -nP -iTCP:$p -sTCP:LISTEN 2>/dev/null | awk 'NR==2 {print $1" (pid "$2")"}')
    printf "  port %-6s %s\n" "$p" "${who:-— not listening}"
  done
}

urls() {
  cat <<'EOS'
  Admin panel   http://localhost:5173    see Qspot-API/.env for the admin login
  Mobile app    http://localhost:8090    see Qspot-API/.env for TEST_LOGIN / TEST_OTP
  API           http://localhost:5001
  MongoDB       mongodb://127.0.0.1:27017/qspot   local database
EOS
}

case "${1:-}" in
  start)
    pgrep -x mongod >/dev/null || brew services start mongodb-community >/dev/null 2>&1 || true
    start_api; start_admin; start_mobile
    sleep 6
    status
    ;;
  stop)
    for l in qspot-api qspot-admin qspot-mobile; do
      launchctl remove "$l" 2>/dev/null && echo "stopped $l" || echo "$l was not running"
    done
    ;;
  status) status ;;
  seed)   (cd "$API" && $NODE22/node scripts/seed-demo.js --force) ;;
  mobile)
    (cd "$MOBILE" && /opt/homebrew/bin/flutter build web --dart-define=API_BASE_URL=http://localhost:5001 --release)
    start_mobile
    ;;
  urls) urls ;;
  *) sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
