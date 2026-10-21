{ inputs, pkgs, ... }:
let
  zenPkgs = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system};

  # zen-browser-flake's auto-update bot bumped to 1.23.3b on 2026-10-16 at
  # 08:43Z and recorded the release asset's hash, but upstream Zen re-uploaded
  # zen.linux-x86_64.tar.xz later the same day (asset created 22:08Z). The
  # pinned hash is therefore stale and every build fails with a fixed-output
  # hash mismatch; the flake's HEAD is already the newest rev, so there is
  # nothing to update to until the bot ships the next version.
  #
  # Re-point the unwrapped derivation at the asset actually being served. The
  # tarball was checked before trusting it: application.ini reports
  # Version=1.23.3b and Gecko 158.0, matching the flake's firefoxVersion.
  #
  # Delete this whole override once the input advances past 1.23.3b — leaving
  # it in place would silently pin the wrong hash onto a future release.
  zenBrowser = zenPkgs.default.override {
    zen-browser-unwrapped = zenPkgs.zen-browser-unwrapped.override {
      hash = "sha256-uyBF0+IWVNQP6EElAJLurf0sH8gx7vtQkiJ3PIvcoUk=";
    };
  };
in
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
    ./desktop/dock
    ./desktop/screenshots.nix
    ./desktop/gaming.nix
    ./desktop/hyprshell.nix

    ./programs/shell.nix
    ./programs/alacritty.nix
    ./programs/editors.nix
  ];

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    zenBrowser
    obsidian
    claude-code
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
