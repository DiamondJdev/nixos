{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi-rofi-wayland;
      extraConfig = {

      };
    };
  };
}
