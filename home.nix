{ inputs, pkgs, ... }:
{
  imports = [
    ./home/shell.nix
    # ./home/git.nix
    # ./home/hyprland.nix
    # ./home/programs.nix
  ];
  home.stateVersion = "24.11";

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
