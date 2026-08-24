# Hyprland is a dynamic tiling Wayland compositor.
{ inputs, pkgs, ... }: {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Generic Wayland hints (Chromium/Electron and Firefox), applied on every
  # Hyprland host regardless of the GPU.
  environment.variables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  security.pam.services.hyprlock = { };
}
