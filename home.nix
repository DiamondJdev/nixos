{ inputs, pkgs, ... }:
{
  imports = [
    ./home/shell.nix
    ./home/notifs.nix
    ./home/rofi.nix
    ./home/waybar.nix
    ./home/wallpaper.nix
    ./home/hyprshell.nix
  ];
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    zed-editor
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    obsidian
    claude-code
    alacritty
    jq
    socat
    # gnome-control-center hardcodes a check refusing to launch outside
    # GNOME/Unity — this scopes XDG_CURRENT_DESKTOP=GNOME to just this
    # one process so it starts, without touching the session-wide
    # XDG_CURRENT_DESKTOP set in hyprland.lua (which stays "Hyprland:KDE"
    # for the portal-selection and KDE-KCM reasons documented there).
    (writeShellScriptBin "settings" ''
      exec env XDG_CURRENT_DESKTOP=GNOME ${gnome-control-center}/bin/gnome-control-center "$@"
    '')
  ];

  programs.git = {
    enable = true;

    settings = {
      user.name = "diamondjdev";
      user.email = "diamondjdev@gmail.com";
    };
  };
}
