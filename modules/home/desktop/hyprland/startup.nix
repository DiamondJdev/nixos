# Session startup — plan §51.4-6.
#
# Autostart is done with systemd user units bound to hyprland-session.target
# rather than with `exec-once`. Home Manager's Hyprland module starts that
# target on compositor launch, and the modules for Waybar, SwayNC, cliphist,
# the wallpaper daemon and the polkit agent already ship their own units, so
# almost nothing needs starting by hand here. The advantages over exec-once
# are concrete: the units restart on failure, they are inspectable with
# `systemctl --user status`, and they stop cleanly on logout instead of
# leaking processes into the next session.
{ pkgs, ... }:
let
  # Ported verbatim (behaviour-wise) from the previous
  # ~/.config/hypr/scripts/fullscreen-preserve.sh. Now built by Nix, so its
  # dependencies are pinned instead of being whatever happened to be on PATH.
  fullscreen-preserve = pkgs.writeShellApplication {
    name = "hypr-fullscreen-preserve";
    runtimeInputs = with pkgs; [
      socat
      jq
      coreutils
    ];
    # The script deliberately reads $HYPRLAND_INSTANCE_SIGNATURE and other
    # runtime-only variables; shellcheck's unassigned-variable warning is
    # noise here.
    excludeShellChecks = [ "SC2154" ];
    text = ''
      # Persistent Hyprland event listener that makes fullscreen "stick"
      # across an Alt-Tab (or any other focus switch), the way Windows does
      # with fullscreen apps/games: Hyprland normally un-fullscreens a window
      # the instant focus leaves it, so switching away from a fullscreened
      # window and back to a windowed one silently drops fullscreen. This
      # restores it on the *destination* window whenever that drop was caused
      # by a focus switch (not by the user manually pressing the toggle).
      #
      # This Hyprland build's socket2 `fullscreen>>N` events turned out to be
      # too noisy to interpret directly by value/position: even a plain focus
      # change between two windows that were never fullscreened emits its own
      # spurious fullscreen 1/0 pairs. So the event stream is only trusted for
      # *when* a switch happens (`activewindowv2`, verified reliable across
      # every test run); the fullscreen state itself is tracked by directly
      # polling `hyprctl activewindow -j` on a short interval in the
      # background and recording it per-window-address under STATE_DIR (one
      # file per address, so polling the *new* active window after a switch
      # can never clobber the *old* window's last known value — the race a
      # single shared state file would have had).
      set -uo pipefail

      SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
      STATE_DIR="$XDG_RUNTIME_DIR/fullscreen-preserve.state.d"
      POLL_INTERVAL=0.15

      rm -rf "$STATE_DIR"
      mkdir -p "$STATE_DIR"

      (
          while true; do
              info=$(hyprctl activewindow -j 2>/dev/null)
              addr=$(printf '%s' "$info" | jq -r '.address // empty' 2>/dev/null)
              fs=$(printf '%s' "$info" | jq -r '.fullscreen // 0' 2>/dev/null)
              if [ -n "$addr" ] && [ -n "$fs" ] && [ "$fs" != "null" ]; then
                  printf '%s' "$fs" > "$STATE_DIR/$addr"
              fi
              sleep "$POLL_INTERVAL"
          done
      ) &
      poller_pid=$!
      trap 'kill "$poller_pid" 2>/dev/null; rm -rf "$STATE_DIR"' EXIT

      current_addr="none"

      socat -U - UNIX-CONNECT:"$SOCK" | while IFS= read -r line; do
          event="''${line%%>>*}"
          payload="''${line#*>>}"

          case "$event" in
              activewindowv2)
                  new_addr="0x$payload"
                  old_addr="$current_addr"
                  if [ -n "$payload" ] && [ "$new_addr" != "$old_addr" ]; then
                      prev_fullscreen=$(cat "$STATE_DIR/$old_addr" 2>/dev/null || echo 0)
                      if [ "''${prev_fullscreen:-0}" != "0" ]; then
                          # Let the switch fully settle before checking/acting,
                          # so we're not racing Hyprland's own in-flight state.
                          sleep 0.15
                          still_windowed=$(hyprctl clients -j | jq -r --arg a "$new_addr" '.[] | select(.address==$a) | .fullscreen // 0')
                          if [ "''${still_windowed:-0}" = "0" ]; then
                              hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "fullscreen" })' >/dev/null 2>&1
                          fi
                      fi
                  fi
                  current_addr="$new_addr"
                  ;;
          esac
      done
    '';
  };
in
{
  # Plan §42: the polkit agent, so privileged desktop actions (mounting a
  # drive in Dolphin, changing a network connection) get a prompt instead of
  # failing silently.
  services.hyprpolkitagent.enable = true;

  systemd.user.services.hypr-fullscreen-preserve = {
    Unit = {
      Description = "Preserve Hyprland fullscreen state across focus switches";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${fullscreen-preserve}/bin/hypr-fullscreen-preserve";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  home.packages = [ fullscreen-preserve ];
}
