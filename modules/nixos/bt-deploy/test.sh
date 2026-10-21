#!/usr/bin/env bash
# Local test for bt-deploy.sh. No root, no systemd: systemctl, journalctl,
# runuser, curl and sqlite3 are stubs that log to calls.log.
# Run: bash modules/nixos/bt-deploy/test.sh
set -uo pipefail

script="$(cd "$(dirname "$0")" && pwd)/bt-deploy.sh"
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/bin" "$T/src/server"

for cmd in systemctl journalctl sqlite3; do
  printf '#!/usr/bin/env bash\necho "%s $*" >> "%s/calls.log"\n' "$cmd" "$T" >"$T/bin/$cmd"
done
# runuser -u <user> -- cmd... runs cmd...
printf '#!/usr/bin/env bash\necho "runuser $*" >> "%s/calls.log"\nshift 3\nexec "$@"\n' "$T" >"$T/bin/runuser"
printf '#!/usr/bin/env bash\necho "curl $*" >> "%s/calls.log"\nexit "$(cat "%s/ready.code")"\n' "$T" "$T" >"$T/bin/curl"
chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH"

export BT_DEPLOY_STATE="$T/state"
export BT_DEPLOY_REPO_URL="$T/src"
export BT_DEPLOY_BRANCH=main
export BT_DEPLOY_USER=nobody
export BT_DEPLOY_SERVICE=bt-assistant.service
export BT_DEPLOY_READY_URL=http://127.0.0.1:8080/ready
export BT_DEPLOY_READY_TIMEOUT=2
export BT_DEPLOY_DB="$T/bt.sqlite3"
export BT_DEPLOY_CHECK='test ! -e FAIL'
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
touch "$BT_DEPLOY_DB"
echo 0 >"$T/ready.code"
git -C "$T/src" init -q -b main

# commit <msg> [fail]: new commit on main; prints its sha
commit() {
  echo "$1" >"$T/src/server/version"
  if [ "${2:-}" = fail ]; then touch "$T/src/server/FAIL"; else rm -f "$T/src/server/FAIL"; fi
  git -C "$T/src" add -A && git -C "$T/src" commit -qm "$1" && git -C "$T/src" rev-parse HEAD
}
# deploy <args>: run bt-deploy, keep stdout+stderr in $out and exit code in $rc
deploy() {
  : >"$T/calls.log"
  out=$("$BASH" "$script" "$@" 2>&1)
  rc=$?
}
fail() {
  echo "FAIL: $1"
  echo "--- output (rc=$rc)"
  echo "$out"
  echo "--- calls.log"
  cat "$T/calls.log"
  exit 1
}
restarts() { grep -c "systemctl restart bt-assistant.service" "$T/calls.log"; }
live() { readlink "$BT_DEPLOY_STATE/current"; }

sha1=$(commit one)
deploy run
[ "$rc" = 0 ] || fail "first deploy: exit code"
[[ "$(live)" == *"$sha1" ]] || fail "first deploy: current"
[ "$(restarts)" = 1 ] || fail "first deploy: one restart"
[ ! -e "$BT_DEPLOY_STATE/testing" ] || fail "first deploy: testing removed"

deploy run
[ "$rc" = 0 ] || fail "no change: exit code"
[ "$(restarts)" = 0 ] || fail "no change: no restart"
[[ "$out" == *"→ no change"* ]] || fail "no change: message"

sha2=$(commit two)
deploy run
[ "$rc" = 0 ] || fail "new commit: exit code"
[[ "$(live)" == *"$sha2" ]] || fail "new commit: current"
[ "$(grep -c '^sqlite3 .*\.backup' "$T/calls.log")" = 1 ] || fail "new commit: one backup"

sha3=$(commit three fail)
deploy run
[ "$rc" = 1 ] || fail "tests fail: exit code"
[[ "$(live)" == *"$sha2" ]] || fail "tests fail: current unchanged"
[ -e "$BT_DEPLOY_STATE/failed/$sha3" ] || fail "tests fail: marked failed"
[ ! -e "$BT_DEPLOY_STATE/testing" ] || fail "tests fail: testing removed"
[ "$(restarts)" = 0 ] || fail "tests fail: no restart"

deploy run
[ "$rc" = 0 ] || fail "failed commit skipped: exit code"
[[ "$out" == *"skipped, failed before"* ]] || fail "failed commit skipped: message"

sha4=$(commit four)
echo 22 >"$T/ready.code"
deploy run
[ "$rc" = 1 ] || fail "not ready: exit code"
[[ "$(live)" == *"$sha2" ]] || fail "not ready: rolled back"
[ "$(restarts)" = 2 ] || fail "not ready: two restarts"
grep -q "not ready" "$BT_DEPLOY_STATE/failed/$sha4" || fail "not ready: reason"

# First deploy ever, not ready: a fresh state dir tracking a branch at sha1.
git -C "$T/src" branch first "$sha1"
BT_DEPLOY_STATE="$T/state2" BT_DEPLOY_BRANCH=first deploy run
[ "$rc" = 1 ] || fail "first deploy not ready: exit code"
[ ! -e "$T/state2/current" ] && [ ! -L "$T/state2/current" ] || fail "first deploy not ready: no current"
[ -e "$T/state2/failed/$sha1" ] || fail "first deploy not ready: marked failed"
echo 0 >"$T/ready.code"

deploy status
[ "$rc" = 0 ] || fail "status: exit code"
grep -q '^origin/main:' <<<"$out" || fail "status: origin/main"
grep -q '^testing: *idle' <<<"$out" || fail "status: testing idle"
grep -q '^live:' <<<"$out" || fail "status: live"
grep -q "^last failed: *${sha4:0:7} .*not ready" <<<"$out" || fail "status: last failed"

for n in 5 6 7 8 9; do
  commit "$n" >/dev/null
  deploy run
  [ "$rc" = 0 ] || fail "pruning: deploy $n"
done
target=$(basename "$(live)")
[ -d "$BT_DEPLOY_STATE/releases/$target" ] || fail "pruning: current kept"
others=$(find "$BT_DEPLOY_STATE/releases" -mindepth 1 -maxdepth 1 ! -name "$target" | wc -l)
[ "$others" -le 3 ] || fail "pruning: at most 3 releases besides current"

echo "all bt-deploy tests passed"
