{
  description = "NixOS Desktop Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    hyprland.url = "github:hyprwm/Hyprland";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          home-manager.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; };
              users.diamondjdev = ./home-manager/home.nix;
            };
          }
          ./modules/ssh.nix # Simply comment to disable
          ./modules/swap.nix
          # ./modules/hypr.nix
          # ./modules/rofi.nix
          # ./modules/dunst.nix
        ];
      };
    };
}
