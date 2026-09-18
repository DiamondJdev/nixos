# Wallpaper — plan §26.
#
# One declarative interface over four very different backends:
#
#   rice.wallpaper = { mode = "video"; source = ./assets/wallpapers/main.mp4; };
#
#   static          awww       still image, any format awww decodes
#   gif             awww       animated GIF (awww animates these natively)
#   video           mpvpaper   looping video via mpv on the background layer
#   wallpaperEngine linux-wallpaperengine   Wallpaper Engine scenes
#
# awww is the current name of the project formerly called swww; nixpkgs'
# `swww` attribute is an alias for it, and the binaries are `awww` /
# `awww-daemon`.
#
# Plan §26's key rule: interactive changes (Waypaper) are temporary. The
# declared source is reapplied on every login and every rebuild, because the
# systemd unit below sets it unconditionally at session start.
{
  config,
  lib,
  pkgs,
  rice,
  ...
}:
let
  cfg = config.rice.wallpaper;

  usesAwww = cfg.mode == "static" || cfg.mode == "gif";
in
{
  options.rice.wallpaper = {
    mode = lib.mkOption {
      type = lib.types.enum [
        "static"
        "gif"
        "video"
        "wallpaperEngine"
      ];
      default = rice.wallpaper.mode;
      description = ''
        Which wallpaper backend to use. Defaults to the value in
        settings.nix, which is the single place §51.16 wants this defined.
      '';
    };

    source = lib.mkOption {
      type = lib.types.either lib.types.path lib.types.str;
      default = rice.wallpaper.source;
      description = ''
        The wallpaper itself. For `wallpaperEngine` this is the numeric
        Steam Workshop ID of the scene rather than a path.
      '';
    };

    enableWaypaper = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install Waypaper, the interactive selector. Note that anything
        selected through it is temporary: the declared `source` is reapplied
        at next login (plan §26).
      '';
    };
  };

  config = lib.mkMerge [
    ################################################################
    ## awww — static images and GIFs
    ################################################################
    (lib.mkIf usesAwww {
      services.awww.enable = true;

      systemd.user.services.wallpaper-set = {
        Unit = {
          Description = "Apply the declaratively configured wallpaper";
          PartOf = [ "graphical-session.target" ];
          After = [
            "graphical-session.target"
            "awww.service"
          ];
          Requires = [ "awww.service" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          # awww-daemon accepts connections slightly after the unit is
          # considered started; `awww query` blocks until it is genuinely
          # ready, which avoids a race that would otherwise leave the
          # wallpaper unset on roughly one login in five.
          ExecStart = pkgs.writeShellScript "wallpaper-set" ''
            for _ in $(seq 1 50); do
              ${pkgs.awww}/bin/awww query >/dev/null 2>&1 && break
              sleep 0.1
            done
            exec ${pkgs.awww}/bin/awww img ${lib.escapeShellArg (toString cfg.source)} \
              --transition-type grow \
              --transition-pos 0.5,0.5 \
              --transition-duration 1 \
              --transition-fps 240
          '';
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    })

    ################################################################
    ## mpvpaper — looping video
    ################################################################
    (lib.mkIf (cfg.mode == "video") {
      systemd.user.services.mpvpaper = {
        Unit = {
          Description = "Video wallpaper (mpvpaper)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          # -o options are passed to mpv itself:
          #   no-audio      a wallpaper must never make noise
          #   loop-file     seamless repeat
          #   hwdec=auto    hand decoding to the 7800 XT rather than the CPU
          #   video-unscaled=no / panscan=1.0  fill the panel, cropping
          #                 rather than letterboxing
          ExecStart = lib.escapeShellArgs [
            "${pkgs.mpvpaper}/bin/mpvpaper"
            "-vs"
            "-o"
            "no-audio loop-file=inf hwdec=auto panscan=1.0 video-sync=display-resample"
            rice.monitor.output
            (toString cfg.source)
          ];
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    })

    ################################################################
    ## linux-wallpaperengine — Wallpaper Engine scenes
    ################################################################
    (lib.mkIf (cfg.mode == "wallpaperEngine") {
      systemd.user.services.linux-wallpaperengine = {
        Unit = {
          Description = "Wallpaper Engine scene wallpaper";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = lib.escapeShellArgs [
            "${pkgs.linux-wallpaperengine}/bin/linux-wallpaperengine"
            "--screen-root"
            rice.monitor.output
            "--silent"
            "--fps"
            "60"
            (toString cfg.source)
          ];
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    })

    ################################################################
    ## Common
    ################################################################
    {
      home.packages =
        lib.optional cfg.enableWaypaper pkgs.waypaper
        ++ lib.optional usesAwww pkgs.awww
        ++ lib.optional (cfg.mode == "video") pkgs.mpvpaper
        ++ lib.optional (cfg.mode == "wallpaperEngine") pkgs.linux-wallpaperengine;

      # Stylix would otherwise start hyprpaper as a *second* wallpaper
      # daemon, which is exactly the "wallpaper services must not duplicate"
      # failure the plan's Phase 7 acceptance tests check for.
      stylix.targets.hyprpaper.enable = false;
    }
  ];
}
