#!/usr/bin/env bash
# bt-deploy: deploy each new commit on the bt-assistant branch after its tests
# pass, and roll back if the service doesn't come up. `run` is the systemd
# unit's entry point; `status`, `now` and `log` are for the owner.
# All paths and settings come from BT_DEPLOY_* (set by default.nix).
set -euo pipefail

usage() {
  echo "usage: bt-deploy <status|now|log>" >&2
  exit 2
}

short() { if [ -n "$1" ]; then echo "${1:0:7}"; else echo none; fi; }

require_env() {
  local v
  for v in BT_DEPLOY_STATE BT_DEPLOY_REPO_URL BT_DEPLOY_BRANCH BT_DEPLOY_USER \
    BT_DEPLOY_SERVICE BT_DEPLOY_READY_URL BT_DEPLOY_READY_TIMEOUT BT_DEPLOY_DB BT_DEPLOY_CHECK; do
    if [ -z "${!v:-}" ]; then
      echo "bt-deploy: $v is not set" >&2
      exit 2
    fi
  done
}

as_user() { runuser -u "$BT_DEPLOY_USER" -- "$@"; }
git_repo() { as_user git --git-dir="$BT_DEPLOY_STATE/repo.git" "$@"; }

# Sha of the release `current` points at, or empty.
live_sha() {
  if [ -L "$BT_DEPLOY_STATE/current" ]; then basename "$(readlink "$BT_DEPLOY_STATE/current")"; fi
}

# Atomic switch: the service never sees a missing or half-written link.
point_current_at() {
  ln -sfn "$BT_DEPLOY_STATE/releases/$1" "$BT_DEPLOY_STATE/current.tmp"
  mv -T "$BT_DEPLOY_STATE/current.tmp" "$BT_DEPLOY_STATE/current"
}

wait_ready() {
  local deadline=$((SECONDS + BT_DEPLOY_READY_TIMEOUT))
  while [ "$SECONDS" -lt "$deadline" ]; do
    if curl -fsS --max-time 5 "$BT_DEPLOY_READY_URL" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

backup_db() {
  if [ ! -e "$BT_DEPLOY_DB" ]; then
    echo "no database at $BT_DEPLOY_DB, skipping backup"
    return 0
  fi
  local dest
  dest="$BT_DEPLOY_STATE/backups/$(short "$1")-$(date -u +%Y%m%dT%H%M%SZ).sqlite3"
  # The DB is private; keep the copy private too.
  (umask 077 && sqlite3 "$BT_DEPLOY_DB" ".backup $dest")
}

# Keep the 3 newest releases plus `current`, and the 5 newest backups.
# Names are shas and timestamps, so parsing ls is safe here.
prune() {
  local keep d
  keep=$(live_sha)
  # shellcheck disable=SC2012
  ls -1t "$BT_DEPLOY_STATE/releases" | tail -n +4 | while read -r d; do
    if [ "$d" != "$keep" ]; then rm -rf "${BT_DEPLOY_STATE:?}/releases/$d"; fi
  done
  # shellcheck disable=SC2012
  ls -1t "$BT_DEPLOY_STATE/backups" | tail -n +6 | while read -r d; do
    rm -f "${BT_DEPLOY_STATE:?}/backups/$d"
  done
}

fetch() {
  local d
  mkdir -p "$BT_DEPLOY_STATE/repo.git" "$BT_DEPLOY_STATE/releases" "$BT_DEPLOY_STATE/failed" ${UV_CACHE_DIR:+"$UV_CACHE_DIR"}
  if [ ! -d "$BT_DEPLOY_STATE/backups" ]; then mkdir -m 0700 "$BT_DEPLOY_STATE/backups"; fi
  if [ "$(id -u)" = 0 ]; then
    for d in "$BT_DEPLOY_STATE/repo.git" "$BT_DEPLOY_STATE/releases" ${UV_CACHE_DIR:+"$UV_CACHE_DIR"}; do
      chown "$BT_DEPLOY_USER:" "$d"
    done
  fi
  if [ ! -e "$BT_DEPLOY_STATE/repo.git/HEAD" ]; then
    as_user git clone --quiet --bare "$BT_DEPLOY_REPO_URL" "$BT_DEPLOY_STATE/repo.git"
  fi
  git_repo fetch --quiet --prune origin "+refs/heads/$BT_DEPLOY_BRANCH:refs/heads/$BT_DEPLOY_BRANCH"
}

cmd_run() {
  require_env
  fetch
  local sha live rel
  sha=$(git_repo rev-parse "refs/heads/$BT_DEPLOY_BRANCH")
  live=$(live_sha)
  local check
  check="check origin=$(short "$sha") live=$(short "$live")"

  if [ "$sha" = "$live" ]; then
    echo "$check → no change"
    return 0
  fi
  if [ -e "$BT_DEPLOY_STATE/failed/$sha" ]; then
    echo "$check → skipped, failed before: $(cat "$BT_DEPLOY_STATE/failed/$sha")"
    return 0
  fi

  echo "$check → testing"
  trap 'rm -f "$BT_DEPLOY_STATE/testing"' EXIT
  echo "$sha" >"$BT_DEPLOY_STATE/testing"

  rel="$BT_DEPLOY_STATE/releases/$sha"
  rm -rf "$rel"
  as_user mkdir "$rel"
  git_repo archive "$sha" | as_user tar -x -C "$rel"
  if ! (cd "$rel/server" && as_user "$BASH" -c "$BT_DEPLOY_CHECK"); then
    echo "tests failed" >"$BT_DEPLOY_STATE/failed/$sha"
    echo "tests failed $(short "$sha")"
    return 1
  fi

  backup_db "$live"
  point_current_at "$sha"
  if systemctl restart "$BT_DEPLOY_SERVICE" && wait_ready; then
    echo "deployed $(short "$sha")"
    prune
    return 0
  fi

  echo "not ready after ${BT_DEPLOY_READY_TIMEOUT}s" >"$BT_DEPLOY_STATE/failed/$sha"
  if [ -n "$live" ]; then
    point_current_at "$live"
    systemctl restart "$BT_DEPLOY_SERVICE" || true
  else
    # Nothing to roll back to: stop rather than crash-loop on a missing tree.
    rm -f "$BT_DEPLOY_STATE/current"
    systemctl stop "$BT_DEPLOY_SERVICE" || true
  fi
  echo "not ready $(short "$sha"), rolled back to $(short "$live")"
  return 1
}

# Read-only; runs as the owner over SSH, so it must not need root.
cmd_status() {
  local state=${BT_DEPLOY_STATE:?BT_DEPLOY_STATE is not set}
  local branch=${BT_DEPLOY_BRANCH:-main} service=${BT_DEPLOY_SERVICE:-bt-assistant.service}
  local last next origin testing running pid cwd failed

  last=$(journalctl -u bt-deploy -t bt-deploy -n 1 -o short-iso --no-pager -q 2>/dev/null || true)
  # A monotonic timer has no NextElapseUSecRealtime; list-timers converts it.
  next=$(systemctl list-timers bt-deploy.timer --all --no-legend 2>/dev/null | awk 'NR == 1 && $1 != "-" { print $2, $3, $4 }' || true)
  origin=$(git --git-dir="$state/repo.git" rev-parse --verify -q "refs/heads/$branch" 2>/dev/null || true)
  testing=idle
  if [ -e "$state/testing" ]; then testing=$(short "$(cat "$state/testing")"); fi

  running=unknown
  pid=$(systemctl show "$service" -p MainPID --value 2>/dev/null || true)
  if [ -n "$pid" ] && [ "$pid" != 0 ] && cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null); then
    running=$(short "$(basename "$(dirname "$cwd")")")
  fi

  # shellcheck disable=SC2012
  failed=$(ls -1t "$state/failed" 2>/dev/null | head -n 1 || true)
  if [ -n "$failed" ]; then failed="$(short "$failed") $(cat "$state/failed/$failed")"; else failed=none; fi

  echo "last check:  ${last:-never}"
  echo "next check:  ${next:-unknown}"
  echo "origin/$branch: $(if [ -n "$origin" ]; then short "$origin"; else echo unknown; fi)"
  echo "testing:     $testing"
  echo "live:        $(short "$(live_sha)")"
  echo "running:     $running"
  echo "last failed: $failed"
}

cmd_now() {
  local follower rc=0
  journalctl -fu bt-deploy -n 0 &
  follower=$!
  # Blocks until the oneshot ends; joins a run already in progress.
  systemctl start bt-deploy.service || rc=$?
  sleep 1
  kill "$follower" 2>/dev/null || true
  wait "$follower" 2>/dev/null || true
  echo
  cmd_status
  exit "$rc"
}

case "${1:-}" in
  run) cmd_run ;;
  status) cmd_status ;;
  now) cmd_now ;;
  log) journalctl -u bt-deploy -n 50 --no-pager "${@:2}" ;;
  *) usage ;;
esac
