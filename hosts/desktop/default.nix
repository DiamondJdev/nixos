# Host: desktop (hostname "nixos")
# Ryzen 7 7800X3D · Radeon RX 7800 XT · 32 GB · single 1920x1080@240 panel
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
    ../../modules/nixos/ssh.nix
    ../../modules/nixos/swap.nix
  ];

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
    # Tailscale service starts at boot, but requires manual auth.
    # After rebuild, run: sudo tailscale up
    openFirewall = true;
  };
  networking.firewall.allowedUDPPorts = [ 41641 ];

  # The onboard NIC is a Realtek RTL8125 2.5GbE controller. The in-kernel
  # r8169 driver has a long-documented link-flap bug on this chip: the
  # link drops and renegotiates (often downshifting to 100Mbps) every
  # 60-90s, which was the actual cause of SteamVR's "Host Machine
  # stopped responding" (error 450) disconnects — confirmed via dmesg
  # timestamps lining up exactly with the SteamVR log's socket-bind
  # failures. Realtek's own out-of-tree r8125 driver doesn't have this
  # bug; blacklist r8169 so it binds instead.
  boot.blacklistedKernelModules = [ "r8169" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.r8125 ];
  boot.kernelModules = [ "r8125" ];

  # The link still flapped after the driver swap above — 24 carrier changes
  # in under two hours, each a ~4s drop, and NOT the 100Mbps downshift the
  # r8169 bug produced (it re-negotiates at the full 2500Mb/s every time).
  # So this is a second, independent fault rather than a regression of the
  # blacklist.
  #
  # `ethtool --show-eee` reports EEE (802.3az Energy Efficient Ethernet)
  # enabled and advertised on 100/1000/2500baseT, while the link partner
  # advertises no EEE modes at all. That mismatch is a long-standing cause of
  # RTL8125 link flapping: the PHY keeps entering and failing to negotiate
  # low-power idle with a switch that will not participate, and drops the
  # link each time. It is worst at 2.5G, which is the rate this link trains
  # at.
  #
  # eee_enable=0 turns it off in the driver itself. The parameter is applied
  # again with ethtool below, because module parameters only take effect when
  # the module loads — without that, this setting would not take hold until
  # the next reboot.
  boot.extraModprobeConfig = ''
    options r8125 eee_enable=0
  '';

  # Belt-and-braces: reassert EEE-off on the live interface. This makes the
  # setting effective immediately on `nixos-rebuild switch` rather than only
  # after a reboot, and re-applies it if the driver is ever reloaded.
  systemd.services.disable-nic-eee = {
    description = "Disable Energy Efficient Ethernet on enp8s0 (link-flap workaround)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    # Failing softly matters: if the interface is renamed or absent, this
    # must not block the boot for a purely optional tuning step.
    script = ''
      if [ -e /sys/class/net/enp8s0 ]; then
        ${pkgs.ethtool}/bin/ethtool --set-eee enp8s0 eee off || true
      fi
    '';
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

  ## Misc services #########################################################
  services.ollama = {
    enable = false;
    package = pkgs.ollama-rocm;
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    nil
    nixd
    btop-rocm
    fastfetch
    ethtool
  ];

  system.stateVersion = "26.05"; # Don't change this
}
