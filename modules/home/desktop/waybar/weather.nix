# Weather provider for Waybar — plan §17.
#
# Requirements the plan sets, and how each is met:
#   "no paid service"          → wttr.in, free and keyless
#   "easy to cache"            → response cached under $XDG_CACHE_HOME
#   "don't query excessively"  → cache honoured for CACHE_TTL (25 min), and
#                                Waybar's own interval is 1800 s
#   "failure must not crash the bar" → every failure path prints valid JSON
#
# That last point is the important one. Waybar's `custom` module in JSON mode
# will render nothing (or log an error and blank the module) if the script
# emits malformed output or exits non-zero. So this script never exits
# non-zero and never prints a partial document: on a network failure it
# reuses the last good cache, and if there is no cache either it emits a
# neutral placeholder.
{ pkgs, rice }:
pkgs.writeShellApplication {
  name = "waybar-weather";
  runtimeInputs = with pkgs; [
    curl
    jq
    coreutils
  ];
  text = ''
    # writeShellApplication injects `set -euo pipefail`. errexit is explicitly
    # disabled here because this script's contract is that it ALWAYS prints
    # valid JSON and exits 0 — plan §17: "if weather retrieval fails, Waybar
    # should not fail". With errexit left on, a failing curl exits before the
    # cache/placeholder fallback below can run, blanking the module.
    set +e
    set -uo pipefail

    LOCATION=${pkgs.lib.escapeShellArg rice.weather.location}
    CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
    CACHE="$CACHE_DIR/weather.json"
    CACHE_TTL=1500 # seconds (25 min)

    mkdir -p "$CACHE_DIR"

    emit_placeholder() {
      jq -nc '{text: "", tooltip: "Weather unavailable", class: "weather-offline"}'
      exit 0
    }

    # Serve from cache while it is still fresh.
    if [ -s "$CACHE" ]; then
      age=$(( $(date +%s) - $(stat -c %Y "$CACHE") ))
      if [ "$age" -lt "$CACHE_TTL" ]; then
        cat "$CACHE"
        exit 0
      fi
    fi

    # wttr.in format j1 returns a full JSON document. --fail makes curl
    # return non-zero on an HTTP error rather than caching an error page.
    raw=$(curl -fsS --max-time 10 "https://wttr.in/''${LOCATION}?format=j1" 2>/dev/null) || true

    if [ -z "$raw" ] || ! printf '%s' "$raw" | jq -e . >/dev/null 2>&1; then
      # Network or parse failure: fall back to the stale cache if we have
      # one, otherwise a neutral placeholder. Never propagate the failure.
      if [ -s "$CACHE" ]; then
        cat "$CACHE"
        exit 0
      fi
      emit_placeholder
    fi

    out=$(printf '%s' "$raw" | jq -c '
      # Map wttr.in weather codes onto Nerd Font glyphs. The code list is
      # coarse on purpose — a handful of buckets reads better in a 12px bar
      # than thirty near-identical icons.
      def icon(code; isday):
        (code | tonumber) as $c
        | if   $c == 113 then (if isday then "" else "" end)
          elif $c == 116 then (if isday then "" else "" end)
          elif $c == 119 or $c == 122 then ""
          elif $c == 143 or $c == 248 or $c == 260 then ""
          elif ($c >= 176 and $c <= 284) then ""
          elif ($c >= 293 and $c <= 314) then ""
          elif ($c >= 317 and $c <= 377) then ""
          elif ($c >= 386 and $c <= 395) then ""
          else "" end;

      .current_condition[0]                as $cur
      | .weather[0]                        as $today
      | .nearest_area[0]                   as $area
      | (($cur.weatherCode)                 | tostring) as $code
      | (($cur.observation_time // "")     | test("AM|PM")) as $_
      | ($cur.temp_F      | tonumber)      as $t
      | ($cur.FeelsLikeF  | tonumber)      as $feels
      | icon($code; true)                  as $ic
      | {
          text: ($ic + "  " + ($t|tostring) + "°"),
          class: "weather",
          tooltip: (
            ($area.areaName[0].value // "Local") + "\n" +
            $cur.weatherDesc[0].value + "\n" +
            "Now      " + ($t|tostring) + "°F (feels " + ($feels|tostring) + "°)\n" +
            "High/Low " + $today.maxtempF + "° / " + $today.mintempF + "°\n" +
            "Humidity " + $cur.humidity + "%\n" +
            "Wind     " + $cur.windspeedMiles + " mph " + $cur.winddir16Point + "\n" +
            "UV       " + ($cur.uvIndex // "-")
          )
        }
    ' 2>/dev/null)

    if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
      if [ -s "$CACHE" ]; then cat "$CACHE"; exit 0; fi
      emit_placeholder
    fi

    printf '%s' "$out" > "$CACHE"
    printf '%s' "$out"
  '';
}
