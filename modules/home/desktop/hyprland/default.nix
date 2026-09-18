# Hyprland — Home Manager owns the configuration (plan §6).
#
# The compositor package itself comes from the NixOS module
# (modules/nixos/desktop.nix); `package`/`portalPackage` are null here so
# Home Manager does not install a second, possibly mismatched copy.
#
# The configuration is emitted as Lua (`configType = "lua"`). Home Manager
# 26.05 supports this natively and Hyprland 0.56 reads
# $XDG_CONFIG_HOME/hypr/hyprland.lua, so this is the format the plan prefers
# rather than a fallback.
#
# The settings tree is assembled from sibling files that are plain functions
# returning attribute-set fragments, NOT modules. That is deliberate: several
# fragments contribute `hl.config(...)` blocks, and merging those through the
# module system would fight over a single option path. Composing them as data
# here keeps the ordering explicit — which matters a great deal for
# rules.nix, where later rules override earlier ones.
{
  lib,
  pkgs,
  rice,
  ...
}:
let
  hlib = import ./lib.nix { inherit lib; };

  # Plan §51.14: the commands the desktop launches, defined once. Bare names
  # rather than store paths — every one of these is put on PATH by this same
  # flake, and the indirection keeps the bindings readable.
  apps = {
    terminal = "alacritty";
    fileManager = "dolphin";
    settings = "settings";
    launcher = "rofi -show drun";
    clipboard = "clipboard-history";
    notificationCenter = "swaync-client -t -sw";
    powerMenu = "power-menu";
    lock = "hyprlock";

    screenshotRegionEdit = "screenshot region-edit";
    screenshotRegionClipboard = "screenshot region-clipboard";
    screenshotFullClipboard = "screenshot full-clipboard";
    screenshotFullEdit = "screenshot full-edit";
  };

  appearance = import ./appearance.nix { inherit rice hlib; };
  animations = import ./animations.nix { inherit rice hlib; };
  bindings = import ./bindings.nix { inherit lib rice hlib apps; };
  rules = import ./rules.nix { inherit lib rice; };
in
{
  imports = [ ./startup.nix ];

  # Stylix's Hyprland target also writes `settings.config`, and that option
  # is unique-valued, so the two definitions collide. It is disabled rather
  # than forced: its Lua output emits flat `col.active_border` keys, which
  # the Lua config form cannot consume (it needs nested `col = { ... }`).
  # Everything it set — border, shadow, group and background colours — is
  # reproduced from rice.palette in ./appearance.nix instead.
  stylix.targets.hyprland.enable = false;

  wayland.windowManager.hyprland = {
    enable = true;

    # Defer to programs.hyprland on the NixOS side.
    package = null;
    portalPackage = null;

    configType = "lua";

    # Starts hyprland-session.target, which everything in startup.nix and the
    # various service modules hang off.
    systemd = {
      enable = true;
      # Import the full environment rather than the default short list, so
      # that user services (Waybar, SwayNC, the wallpaper daemon) inherit the
      # same PATH and Wayland variables the compositor itself has.
      variables = [ "--all" ];
    };

    settings = {
      ## Monitor — plan §7 ##################################################
      monitor = {
        output = rice.monitor.output;
        mode = rice.monitor.mode;
        position = rice.monitor.position;
        scale = rice.monitor.scale;
      };

      ## Environment ########################################################
      env = [
        (hlib.env "XCURSOR_SIZE" (toString 24))
        (hlib.env "HYPRCURSOR_SIZE" (toString 24))
        # Electron/Chromium apps (VS Code, Zen's embedded views, Discord)
        # default to XWayland without this, which costs them fractional
        # scaling, correct cursor size and smooth resize.
        (hlib.env "NIXOS_OZONE_WL" "1")
        # Qt apps pick their platform theme from here; with Plasma gone this
        # is what points them at the Stylix-generated qt6ct configuration.
        (hlib.env "QT_QPA_PLATFORMTHEME" "qt6ct")
      ];

      # Several fragments each contribute an `hl.config{...}` block; a list
      # renders as one call per element, which is exactly how the previous
      # hand-written config was structured too.
      config = [
        appearance.config
        animations.config
      ];

      curve = animations.curve;
      animation = animations.animation;

      bind = bindings.bind;
      device = bindings.device;
      gesture = bindings.gesture;

      window_rule = rules.window_rule;
      layer_rule = rules.layer_rule;
      workspace_rule = rules.workspace_rule;
    };
  };
}
