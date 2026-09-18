{
  description = "NixOS Desktop Flake — Hyprland floating rice";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    zen-browser.url = "github:youwen5/zen-browser-flake";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      stylix,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Centralised rice data (palette, monitor, fonts, dock pins, wallpaper).
      # Threaded into BOTH option trees so neither NixOS nor Home Manager
      # modules have to restate a colour or a resolution. See ./settings.nix.
      rice = import ./settings.nix { inherit pkgs; };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs rice; };
        modules = [
          ./hosts/desktop

          home-manager.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs rice; };
              users.diamondjdev = ./modules/home;
              # Move pre-existing unmanaged dotfiles aside rather than
              # aborting the activation. Needed for the migration off the
              # hand-written ~/.config/hypr/hyprland.lua.
              backupFileExtension = "hm-bak";
            };
          }

          stylix.nixosModules.stylix
        ];
      };
    };
}
