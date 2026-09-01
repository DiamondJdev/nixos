# Dock — plan §20.
#
# nwg-dock-hyprland is the Hyprland-specific build of nwg-dock; it reads the
# Hyprland IPC socket directly, so "show running applications" and
# click-to-focus work without a compositor-agnostic shim.
#
# Behaviour required by §20 and the flags that provide it:
#   centred at bottom            -p bottom -a center
#   hidden normally, edge reveal -d (auto-hide: show on hotspot hover)
#   hides when apps overlap      consequence of NOT passing -x, so the dock
#                                claims no exclusive zone and simply layers
#                                over/under rather than reserving space
#   pinned applications          the nwg-dock-pinned file, generated below
#   running applications         built in to this variant
{
  lib,
  pkgs,
  rice,
  ...
}:
let
  dockPkg = pkgs.nwg-dock-hyprland;

  # Plan §20: "Do not hardcode applications that are not installed."
  #
  # The pin list is declared once in settings.nix as .desktop IDs, but
  # whether a given ID resolves depends on what is actually installed. This
  # generator runs at service start and keeps only the IDs it can find on
  # XDG_DATA_DIRS, so an uninstalled application degrades to simply being
  # absent from the dock instead of rendering as a broken tile.
  generatePinned = pkgs.writeShellApplication {
    name = "nwg-dock-generate-pinned";
    runtimeInputs = with pkgs; [
      jq
      coreutils
    ];
    text = ''
      target="''${XDG_CONFIG_HOME:-$HOME/.config}/nwg-dock-hyprland"
      mkdir -p "$target"

      declared=(${lib.concatStringsSep " " (map lib.escapeShellArg rice.dockPins)})

      found=()
      for id in "''${declared[@]}"; do
        # Search every data dir on the path, plus the two profile locations
        # that Home Manager and NixOS use.
        IFS=':' read -ra dirs <<< "''${XDG_DATA_DIRS:-/usr/share}"
        dirs+=("$HOME/.nix-profile/share" "/run/current-system/sw/share")
        for d in "''${dirs[@]}"; do
          if [ -f "$d/applications/$id.desktop" ]; then
            found+=("$d/applications/$id.desktop")
            break
          fi
        done
      done

      # nwg-dock stores its pins as a flat JSON array of .desktop paths.
      printf '%s\n' "''${found[@]:-}" \
        | jq -R . \
        | jq -sc 'map(select(length > 0))' \
        > "$target/nwg-dock-pinned"
    '';
  };
in
{
  home.packages = [ dockPkg ];

  # The dock's stylesheet is read from this fixed path, not from a flag.
  xdg.configFile."nwg-dock-hyprland/style.css".text = import ./style.nix {
    inherit rice;
  };

  # The auto-hide hotspot is a separate GTK layer surface that sizes itself
  # to its content. Left alone it comes out 4x3 PIXELS at the bottom centre,
  # which is effectively impossible to hit — the dock appeared never to work.
  # nwg-dock looks for an optional hotspot.css, and a min-height there grows
  # the surface. Measured with `hyprctl layers`: 4x3 without this file,
  # 236x22 with it.
  xdg.configFile."nwg-dock-hyprland/hotspot.css".text = ''
    window {
      min-width: 700px;
      min-height: 16px;
      background: transparent;
    }
  '';

  systemd.user.services.nwg-dock = {
    Unit = {
      Description = "nwg-dock-hyprland application dock";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${generatePinned}/bin/nwg-dock-generate-pinned";
      ExecStart = lib.escapeShellArgs [
        "${dockPkg}/bin/nwg-dock-hyprland"
        "-d" # auto-hide behind a bottom hotspot
        "-p"
        "bottom"
        "-a"
        "center"
        "-i"
        "40" # icon size
        "-mb"
        "8" # lift it clear of the screen edge
        # 0 = reveal as soon as the pointer enters the hotspot. With a
        # non-zero value the pointer also has to be moving slowly enough,
        # which combined with a thin hotspot makes the dock feel broken.
        "-hd"
        "0"
        "-l"
        "overlay"
        "-nolauncher" # Rofi is the launcher (§21); a second one is clutter
        "-o"
        rice.monitor.output
        # Don't show the wallpaper/bar surfaces as if they were apps.
        "-g"
        "awww mpvpaper waybar"
      ];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
