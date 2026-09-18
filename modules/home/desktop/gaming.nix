# Gaming behaviour — plan §10, §45.
#
# The plan's hard constraint (§45): "Do not use fragile global scripts that
# leave the compositor in the wrong state if a game crashes. Prefer reversible
# state changes." Two mechanisms are used, and neither can strand the desktop:
#
#  1. Per-window rules (modules/home/desktop/hyprland/rules.nix) disable blur,
#     shadow, animation and dimming *for the game window only*. Nothing global
#     changes, so when the window disappears — cleanly or by crashing — the
#     effects are simply no longer suppressed. There is nothing to restore.
#
#  2. gamemode's start/end hooks handle the things that genuinely are global:
#     pausing the video wallpaper and silencing notifications. gamemoded
#     tracks the requesting process and runs the `end` hook when it exits
#     *including on a crash or SIGKILL*, which is precisely the reversibility
#     the plan asks for. A bare wrapper script could not promise that.
{ pkgs, ... }:
let
  # Pause/resume whichever wallpaper backend is actually running. Both
  # branches are no-ops when that backend isn't in use, so this same script
  # is correct for every rice.wallpaper.mode.
  gameStart = pkgs.writeShellScript "gamemode-start" ''
    # Video wallpaper: SIGSTOP rather than stopping the unit, so resuming is
    # instant and mpv keeps its decoded state and position.
    ${pkgs.procps}/bin/pkill -STOP -x mpvpaper 2>/dev/null || true

    # awww's daemon costs nothing while a fullscreen game is on top (it only
    # redraws on change), so it is deliberately left alone.

    # Silence notifications for the duration (§45).
    ${pkgs.swaynotificationcenter}/bin/swaync-client --dnd-on 2>/dev/null || true
  '';

  gameEnd = pkgs.writeShellScript "gamemode-end" ''
    ${pkgs.procps}/bin/pkill -CONT -x mpvpaper 2>/dev/null || true
    ${pkgs.swaynotificationcenter}/bin/swaync-client --dnd-off 2>/dev/null || true
  '';
in
{
  # gamemode reads this from the user's config; the daemon itself is enabled
  # system-wide in modules/nixos/graphics.nix.
  xdg.configFile."gamemode.ini".text = ''
    [general]
    ; Ask the CPU governor for performance while a game is running. Reverted
    ; automatically when the game exits.
    desiredgov=performance
    softrealtime=auto
    renice=10

    [custom]
    start=${gameStart}
    end=${gameEnd}
  '';

  home.packages = with pkgs; [
    gamemode
    mangohud
  ];
}
