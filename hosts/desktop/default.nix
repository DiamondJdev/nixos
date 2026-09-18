# Host: desktop (hostname "nixos")
{ pkgs, config, ... }:
{
  imports = [
    ./hardware.nix

    ../../modules/nixos/desktop.nix
    ../../modules/nixos/graphics.nix
    ../../modules/nixos/peripherals.nix
    ../../modules/nixos/fonts.nix
    ../../modules/nixos/theming.nix
    ../../modules/nixos/login.nix
    ../../modules/nixos/nic.nix
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/swap.nix
    ../../modules/nixos/bt-assistant.nix
  ];

  # App code: ~/Projects/bt-assistant
  services.bt-assistant.enable = true;

  networking.hostName = "nixos";

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 15;
  };
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 20;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    trusted-users = [
      "root"
      "diamondjdev"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config = {
    allowUnfree = true;
    rocmSupport = true;
  };

  ## Networking ############################################################
  networking.networkmanager.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.tailscale-serve = {
    description = "Tailscale Serve for BT Assistant";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      # 443 -> stable bt-assistant systemd service (8080).
      # 8081 -> ad-hoc dev instance you start by hand
      ExecStart = "${pkgs.writeShellScript "bt-tailscale-serve" ''
        set -e
        ${config.services.tailscale.package}/bin/tailscale serve --bg http://127.0.0.1:8080
        ${config.services.tailscale.package}/bin/tailscale serve --bg --https=8081 http://127.0.0.1:8081
      ''}";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  networking.firewall = {
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  ## Locale ################################################################
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  ## User ##################################################################
  programs.zsh.enable = true; # NixOS requires this for a zsh login shell,
  # even though the configuration itself lives in Home Manager.
  users.users."diamondjdev" = {
    isNormalUser = true;
    description = "Cameron";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    nil
    nixd
    btop-rocm
    fastfetch
  ];

  system.stateVersion = "26.05"; # Don't change this
}
