{
  description = "NixOS Desktop Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    hyprland.url = "github:hyprwm/Hyprland";

  };

  outputs =
    { nixpkgs, ... }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          ./modules/ssh.nix # Simply comment to disable
          ./modules/swap.nix
          ./modules/shell.nix
          ./modules/hypr.nix
          ./modules/rofi.nix
        ];
      };
    };
}
