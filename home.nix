{ inputs, pkgs, ... }:
{
  imports = [
    ./home/shell.nix
    ./home/notifs.nix
    ./home/rofi.nix
    ./home/waybar.nix
  ];
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    zed-editor
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    obsidian
    claude-code
    alacritty
  ];

  programs.git = {
    enable = true;

    settings = {
      user.name = "diamondjdev";
      user.email = "diamondjdev@gmail.com";
    };
  };
}
