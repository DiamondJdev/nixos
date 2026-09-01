# Rofi — application launcher and clipboard frontend (plan §21).
#
# nixpkgs' `rofi` is now version 2.0, which merged the old rofi-wayland fork
# upstream: it speaks Wayland natively, so no separate -wayland package is
# needed (and `rofi-wayland` no longer exists in nixpkgs).
#
# Colours come from rice.palette. The previous version of this file read
# `config.stylix.base16Scheme.base00`, which only worked while base16Scheme
# was an attribute set; it is now a path to a scheme file, so those
# references would fail to evaluate.
{
  config,
  lib,
  rice,
  ...
}:
let
  inherit (config.lib.formats.rasi) mkLiteral;
  inherit (rice) palette accent radius fonts;
  c = name: mkLiteral (rice.withHash palette.${name});
in
{
  # Stylix would generate its own rofi theme and fight this one. The hand
  # written theme is the intentional custom styling plan §12 says to protect.
  stylix.targets.rofi.enable = false;

  programs.rofi = {
    enable = true;

    extraConfig = {
      modi = "drun,run,filebrowser";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      # 0 = centre of the screen (plan §21).
      location = 0;
      drun-display-format = "{name}";
      display-drun = "";
      display-run = "";
      display-filebrowser = "";
      sidebar-mode = false;
      hover-select = true;
      me-select-entry = "";
      me-accept-entry = "MousePrimary";
    };

    theme = {
      "*" = {
        bg = c "base";
        bg-alt = c "surface0";
        fg = c "text";
        fg-dim = c "subtext0";
        accent = mkLiteral (rice.withHash accent);
        urgent = c "red";

        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };

      "window" = {
        width = mkLiteral "620px";
        transparency = "real"; # let the Hyprland layer rule blur behind it
        location = mkLiteral "center";
        anchor = mkLiteral "center";
        border = mkLiteral "2px";
        border-color = mkLiteral "@accent";
        border-radius = mkLiteral "${toString radius.panel}px";
        # Alpha here is what the blur shows through.
        background-color = mkLiteral "${rice.withHash palette.base}e6";
      };

      "mainbox" = {
        padding = mkLiteral "16px";
        spacing = mkLiteral "14px";
        children = map mkLiteral [
          "inputbar"
          "listview"
        ];
      };

      # Plan §21: a large search box is the focal point.
      "inputbar" = {
        padding = mkLiteral "14px 16px";
        spacing = mkLiteral "12px";
        border-radius = mkLiteral "${toString radius.control}px";
        background-color = mkLiteral "${rice.withHash palette.surface0}b3";
        children = map mkLiteral [
          "prompt"
          "entry"
        ];
      };

      "prompt" = {
        enabled = true;
        text-color = mkLiteral "@accent";
        font = "${fonts.mono.name} ${toString fonts.sizes.launcher}";
      };

      "entry" = {
        placeholder = "Search";
        placeholder-color = mkLiteral "@fg-dim";
        text-color = mkLiteral "@fg";
        cursor = mkLiteral "text";
        font = "${fonts.ui.name} ${toString fonts.sizes.launcher}";
      };

      "listview" = {
        lines = 8;
        columns = 1;
        fixed-height = false;
        scrollbar = false;
        spacing = mkLiteral "4px";
      };

      "element" = {
        padding = mkLiteral "10px 12px";
        spacing = mkLiteral "12px";
        border-radius = mkLiteral "${toString radius.control}px";
        cursor = mkLiteral "pointer";
      };

      "element normal.normal" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };
      "element alternate.normal" = {
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "@fg";
      };
      "element selected.normal" = {
        background-color = mkLiteral "@accent";
        text-color = mkLiteral "${rice.withHash palette.base}";
      };
      "element normal.urgent" = {
        background-color = mkLiteral "@urgent";
        text-color = mkLiteral "${rice.withHash palette.base}";
      };
      "element selected.urgent" = {
        background-color = mkLiteral "@urgent";
        text-color = mkLiteral "${rice.withHash palette.base}";
      };

      "element-icon" = {
        size = mkLiteral "26px";
        cursor = mkLiteral "inherit";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
      };

      "element-text" = {
        vertical-align = mkLiteral "0.5";
        cursor = mkLiteral "inherit";
        background-color = mkLiteral "transparent";
        text-color = mkLiteral "inherit";
        font = "${fonts.ui.name} ${toString fonts.sizes.launcher}";
      };

      "message" = {
        border-radius = mkLiteral "${toString radius.control}px";
        background-color = mkLiteral "${rice.withHash palette.surface0}b3";
        padding = mkLiteral "10px";
      };
      "textbox" = {
        text-color = mkLiteral "@fg";
      };
    };
  };
}
