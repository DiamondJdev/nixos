# Stylix — the global theme foundation (plan §12).
#
# Stylix owns the *broad strokes*: it pushes the palette, fonts, cursor and
# icon theme into every application that has a Stylix target (GTK, Qt, VS
# Code, Zed, Alacritty, …) without those applications each restating the
# colours. Hand-written CSS (Waybar, SwayNC, Rofi, wlogout) reads the very
# same values out of ./settings.nix, so the two halves cannot drift.
#
# Plan §12 also warns not to let Stylix stomp intentional custom styling.
# Targets that would fight the hand-written CSS are disabled individually in
# the Home Manager modules that own that styling, rather than by turning
# autoEnable off wholesale.
{ pkgs, rice, ... }:
{
  stylix = {
    enable = true;
    autoEnable = true;
    polarity = "dark";

    # The palette is pinned to the Catppuccin Mocha base16 scheme rather than
    # generated from the wallpaper. Plan §11 wants a known, stable palette;
    # image-derived colours would shift every time the wallpaper changes and
    # would not match the named Mauve/Lavender/Sapphire the design calls for.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

    # Still image only — see settings.nix. Used by Stylix's own targets as a
    # background; the live wallpaper is managed separately (plan §26) by
    # modules/home/desktop/wallpaper.
    image = rice.wallpaper.still;

    cursor = {
      package = pkgs.catppuccin-cursors.mochaMauve;
      name = "catppuccin-mocha-mauve-cursors";
      size = 24; # plan §38: sensible at 1080p
    };

    icons = {
      enable = true;
      package = pkgs.papirus-icon-theme;
      dark = "Papirus-Dark";
      light = "Papirus";
    };

    fonts = {
      sansSerif = rice.fonts.ui;
      serif = rice.fonts.ui;
      monospace = rice.fonts.mono;
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        desktop = rice.fonts.sizes.bar;
        applications = rice.fonts.sizes.bar;
        terminal = rice.fonts.sizes.terminal;
        popups = rice.fonts.sizes.notification;
      };
    };

    # Plan §44: a readability hierarchy, not one flat transparency. Windows
    # used for dense reading stay closer to opaque than overlay chrome does.
    # Note these are Stylix's *application-level* opacities; Hyprland applies
    # its own compositor-level opacity on top (see hyprland/appearance.nix),
    # so they are kept mild here to avoid the two multiplying into something
    # unreadable.
    opacity = {
      applications = 1.0;
      terminal = rice.opacity.terminal;
      desktop = 1.0;
      popups = 1.0;
    };

    # qtct is the only Qt platform Stylix currently supports; with Plasma
    # gone this is also the right one (the previous "kde" setting emitted an
    # unsupported-platform warning on every build).
    targets.qt.platform = "qtct";
  };
}
