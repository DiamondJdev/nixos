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
  services.bt-assistant.enable = false;

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

  # Expose the BT assistant webapp on this node's own tailscale IP so any
  # device in the tailnet can reach it at <tailscale-ip>:8080.
  systemd.services.tailscale-serve = {
    description = "Tailscale Serve for BT Assistant";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --bg --tcp 8080 localhost:8080";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  networking.firewall = {
    trustedInterfaces = [ config.services.tailscale.interfaceName ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # The onboard NIC is a Realtek RTL8125 2.5GbE controller. The in-kernel
  # r8169 driver has a long-documented link-flap bug on this chip: the
  # link drops and renegotiates (often downshifting to 100Mbps) every
  # 60-90s, which was the actual cause of SteamVR's "Host Machine
  # stopped responding" (error 450) disconnects — confirmed via dmesg
  # timestamps lining up exactly with the SteamVR log's socket-bind
  # failures. Realtek's own out-of-tree r8125 driver doesn't have this
  # bug; blacklist r8169 so it binds instead.
  # boot.blacklistedKernelModules = [ "r8169" ];
  # boot.extraModulePackages = [ config.boot.kernelPackages.r8125 ];
  # boot.kernelModules = [ "r8125" ];

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
