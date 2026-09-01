# Fonts — plan §13.
{ pkgs, rice, ... }:
{
  fonts = {
    packages = [
      rice.fonts.ui.package
      rice.fonts.mono.package
    ]
    ++ (with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      font-awesome # some Waybar/Rofi glyph sets still reference FA names
    ]);

    # Make the two chosen families the actual answer to a generic request,
    # so applications that ask fontconfig for "sans-serif" or "monospace"
    # (most GTK/Qt apps, and every terminal fallback path) land on Inter and
    # JetBrainsMono rather than on DejaVu.
    fontconfig.defaultFonts = {
      sansSerif = [ rice.fonts.ui.name ];
      serif = [ rice.fonts.ui.name ];
      monospace = [ rice.fonts.mono.name ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
