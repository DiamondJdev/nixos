# Centralised rice data.
#
# This is a plain attribute set (NOT a NixOS/Home Manager module) so that the
# exact same values can be threaded into both the NixOS and the Home Manager
# option trees, which are otherwise separate namespaces. It is passed through
# `specialArgs`/`extraSpecialArgs` in flake.nix and lands in every module as
# the `rice` argument.
#
# Plan §51.12-16: keep theme values, monitor values, application rules,
# pinned dock apps and the wallpaper source each defined in exactly one place.
# Retheming to Titanfall 2 / ULTRAKILL later (plan §13) should mostly be a
# matter of rewriting `palette` and `wallpaper` here, not touching modules.
{ pkgs }:
rec {
  ##########################################################################
  ## Palette — Catppuccin Mocha
  ##########################################################################
  # Named colours rather than base16 slots, because the design language in
  # the plan is expressed in Catppuccin's own vocabulary ("Mauve accent,
  # Lavender/Sapphire secondary"). Stylix still gets the matching base16
  # scheme (see modules/nixos/theming.nix) so that apps Stylix knows how to
  # theme stay consistent with the hand-written CSS that reads these.
  #
  # Stored WITHOUT a leading '#'. Use `withHash` / `rgba` helpers below.
  palette = {
    base = "1e1e2e";
    mantle = "181825";
    crust = "11111b";

    surface0 = "313244";
    surface1 = "45475a";
    surface2 = "585b70";

    overlay0 = "6c7086";
    overlay1 = "7f849c";
    overlay2 = "9399b2";

    subtext0 = "a6adc8";
    subtext1 = "bac2de";
    text = "cdd6f4";

    rosewater = "f5e0dc";
    flamingo = "f2cdcd";
    pink = "f5c2e7";
    mauve = "cba6f7";
    red = "f38ba8";
    maroon = "eba0ac";
    peach = "fab387";
    yellow = "f9e2af";
    green = "a6e3a1";
    teal = "94e2d5";
    sky = "89dceb";
    sapphire = "74c7ec";
    blue = "89b4fa";
    lavender = "b4befe";
  };

  # Semantic roles. Modules should prefer these over reaching for a literal
  # colour name, so a reskin only has to remap a handful of entries.
  accent = palette.mauve;
  accentAlt = palette.lavender;
  accentCool = palette.sapphire;
  urgent = palette.red;
  warning = palette.peach;
  success = palette.green;

  ##########################################################################
  ## Helpers
  ##########################################################################
  withHash = c: "#${c}";
  # Hyprland wants rgba() with an 8-digit hex (colour + alpha).
  rgba = c: a: "rgba(${c}${a})";

  ##########################################################################
  ## Monitor — plan §7
  ##########################################################################
  # NOTE: the plan specifies 244 Hz, but this panel (AOC 27G2G8 on HDMI-A-1)
  # reports a maximum mode of 1920x1080@239.964 — there is no 244 Hz mode in
  # its EDID. 239.964 is the real ceiling and is what "244 Hz" is marketed
  # as. Verified with `hyprctl monitors all`.
  monitor = {
    output = "HDMI-A-1";
    width = 1920;
    height = 1080;
    refresh = "239.964";
    scale = 1;
    position = "auto";
    mode = "1920x1080@239.964";
  };

  ##########################################################################
  ## Floating window geometry — plan §8
  ##########################################################################
  # ~70% of screen width, ~74% of height at 1920x1080.
  floating = {
    widthPct = 70;
    heightPct = 74;
    width = 1344; # 1920 * 0.70
    height = 800; # 1080 * 0.74
  };

  ##########################################################################
  ## Fonts — plan §13
  ##########################################################################
  fonts = {
    ui = {
      name = "Inter";
      package = pkgs.inter;
    };
    mono = {
      name = "JetBrainsMono Nerd Font";
      package = pkgs.nerd-fonts.jetbrains-mono;
    };
    sizes = {
      bar = 12;
      terminal = 12;
      notification = 12;
      launcher = 13;
      lockClock = 90;
      lockDate = 18;
    };
  };

  ##########################################################################
  ## Surface styling — plan §14, §44
  ##########################################################################
  opacity = {
    active = 0.95;
    inactive = 0.91;
    terminal = 0.90;
    menu = 0.92;
    bar = 0.85;
    notificationCenter = 0.92;
  };

  radius = {
    window = 10;
    island = 14;
    panel = 16;
    control = 10;
  };

  border = {
    size = 2;
    gapsIn = 5;
    gapsOut = 12;
  };

  ##########################################################################
  ## Dock pins — plan §20, §51.15
  ##########################################################################
  # Only .desktop IDs for applications this flake actually installs. The dock
  # module drops any entry whose .desktop file is missing at build time, so
  # an uninstalled app degrades to "absent" instead of a broken tile.
  dockPins = [
    "zen-beta"
    "org.kde.dolphin"
    "Alacritty"
    "code"
    "dev.zed.Zed"
    "steam"
  ];

  ##########################################################################
  ## Wallpaper — plan §26, §51.16
  ##########################################################################
  # mode ∈ "static" | "gif" | "video" | "wallpaperEngine"
  wallpaper = {
    mode = "static";
    source = ./assets/wallpapers/TF2.jpg;

    # Always a STILL image, even when `mode` is "video"/"wallpaperEngine".
    # Stylix, Hyprlock, wlogout and SDDM all need something they can blur
    # and composite; they read this rather than `source`.
    still = ./assets/wallpapers/TF2.jpg;
  };

  ##########################################################################
  ## Weather — plan §17
  ##########################################################################
  # Empty string = let wttr.in geolocate by IP. Set to e.g. "Chicago" to pin.
  weather.location = "";

  ##########################################################################
  ## Profile image — plan §24, §33
  ##########################################################################
  profileImage = ./assets/profile/avatar.png;
}
