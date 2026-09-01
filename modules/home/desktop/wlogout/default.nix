# wlogout — the graphical power menu (plan §23).
#
# Plan §23 is explicit that this must NOT be a Rofi menu: it wants a
# fullscreen presentation with large horizontally-arranged actions over the
# wallpaper.
{
  pkgs,
  rice,
  ...
}:
let
  # wlogout ships good icon artwork, but two things must be fixed before GTK
  # will draw any of it:
  #
  #  1. The SVGs carry no `fill`, so their paths default to black and are
  #     invisible against the dark overlay. Children inherit `fill` from an
  #     ancestor, so injecting it on the root <svg> recolours the whole set.
  #
  #  2. They must not remain SVGs. GTK decodes CSS background-image through
  #     gdk-pixbuf, and SVG support there requires the librsvg loader to be
  #     registered via GDK_PIXBUF_MODULE_FILE. nixpkgs' wlogout is a bare,
  #     unwrapped ELF with no such wrapper, so an SVG background silently
  #     renders as nothing — which is why even the stock icons never
  #     appeared. Rasterising to PNG at build time sidesteps the loader
  #     entirely, since gdk-pixbuf decodes PNG natively with no module to
  #     locate at runtime.
  icons = pkgs.runCommand "wlogout-icons-themed" { } ''
    mkdir -p "$out"
    for svg in ${pkgs.wlogout}/share/wlogout/assets/*.svg; do
      name=$(basename "$svg" .svg)
      ${pkgs.gnused}/bin/sed \
        's|<svg |<svg fill="${rice.withHash rice.palette.text}" |' \
        "$svg" > recoloured.svg
      ${pkgs.librsvg}/bin/rsvg-convert \
        --width 128 --height 128 --keep-aspect-ratio \
        --format png \
        --output "$out/$name.png" \
        recoloured.svg
    done
  '';

  # Single definition of "open the power menu", referenced by both the
  # Hyprland binding and the Waybar power button, so the two can never
  # disagree about the geometry flags.
  #   -b 5  five buttons in one row (plan §23: horizontally arranged)
  #   -c/-r column/row margins as a fraction of the screen — these are what
  #         make the row large and centred rather than edge-to-edge.
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    exec ${pkgs.wlogout}/bin/wlogout -b 5 -c 0 -r 0 --protocol layer-shell "$@"
  '';
in
{
  home.packages = [ power-menu ];

  programs.wlogout = {
    enable = true;

    # Plan §23 required actions: exit, shutdown, suspend, reboot; lock is
    # listed as optional and is included since it is cheap and useful.
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        # Exits Hyprland, returning to SDDM.
        action = "hyprctl dispatch 'hl.dsp.exit()'";
        text = "Log out";
        keybind = "e";
      }
      {
        label = "suspend";
        # loginctl lock-session first so the session is locked *before* the
        # machine goes down; hypridle's before_sleep_cmd covers the paths
        # that don't come through here.
        action = "loginctl lock-session && systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];

    style = import ./style.nix { inherit rice icons; };
  };
}
