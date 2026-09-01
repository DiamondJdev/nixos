# Wallpaper — interim.
#
# Phase 1 only needs *a* working wallpaper. The previous config pointed
# hyprpaper at the relative string "./rice/imgs/TF2.jpg", which hyprpaper
# resolves against its own working directory and therefore never found — the
# wallpaper silently failed to load. Using the Nix path makes it a store
# path, which always resolves.
#
# The declarative multi-backend abstraction the plan asks for (§26:
# static/gif/video/wallpaperEngine behind `rice.wallpaper.mode`) replaces
# this wholesale in Phase 7.
{ rice, ... }:
{
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [ "${rice.wallpaper.still}" ];
      wallpaper = [
        {
          monitor = "";
          path = "${rice.wallpaper.still}";
        }
      ];
    };
  };
}
