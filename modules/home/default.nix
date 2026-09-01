{ inputs, pkgs, ... }:
{
  imports = [
    ./desktop/hyprland
    ./desktop/waybar
    ./desktop/rofi
    ./desktop/clipboard.nix
    ./desktop/wallpaper
    ./desktop/swaync
    ./desktop/wlogout
    ./desktop/hyprlock.nix
    ./desktop/hyprshell.nix

    ./programs/shell.nix
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
    gh

    # gnome-control-center hardcodes a check refusing to launch outside
    # GNOME/Unity — this scopes XDG_CURRENT_DESKTOP=GNOME to just this
    # one process so it starts, without touching the session-wide
    # XDG_CURRENT_DESKTOP, which is now plain "Hyprland".
    #
    # Its Network/Bluetooth/Sound/Power panels talk to real, independent
    # daemons (NetworkManager/BlueZ/PipeWire) so those work standalone.
    # Its Mouse & Touchpad and some Display panels write to GNOME's own
    # config store, which Hyprland never reads — those panels will look
    # normal but silently do nothing; mouse sensitivity and monitor config
    # live in modules/home/desktop/hyprland instead.
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

  programs.home-manager.enable = true;
}
