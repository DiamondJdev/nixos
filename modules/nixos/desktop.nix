# Compositor, display manager, portals, polkit and the Qt/file-manager
# integration that Plasma used to provide.
{
  inputs,
  pkgs,
  ...
}:
let
  hyprPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  ## Hyprland ##############################################################
  # Plan §6: the compositor package and its system integration are owned by
  # NixOS; the *configuration* is owned by Home Manager. Hyprland and
  # xdg-desktop-portal-hyprland are taken from the same flake input so their
  # versions can never drift apart.
  programs.hyprland = {
    enable = true;
    package = hyprPkgs.hyprland;
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
    withUWSM = false;
  };

  ## Display manager #######################################################
  # SDDM is deliberately left on its X11 backend. It is the configuration
  # that is known to work on this machine, and plan §52 ranks session
  # stability above visual polish — a themed login screen that cannot start
  # is strictly worse than a plain one that can. The X server here backs
  # only the greeter; the session itself is pure Wayland.
  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.displayManager.sddm.enable = true;

  ## Portals ###############################################################
  # Plan §43: exactly one implementation per interface. Plasma's
  # xdg-desktop-portal-kde is gone along with Plasma itself, so the
  # XDG_CURRENT_DESKTOP="Hyprland:KDE" hack that used to be needed to steer
  # portal selection away from it is no longer necessary either — the
  # session now advertises plain "Hyprland".
  #
  # hyprland handles screencopy/screenshot/screencast; gtk handles the
  # file chooser and settings (appearance/colour-scheme) interfaces, which
  # xdph does not implement.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
  };

  ## Authentication ########################################################
  # Plan §42. hyprpolkitagent ships a user service; Home Manager starts it
  # (see modules/home/desktop/hyprland/startup.nix). security.polkit must be
  # on for the agent to have anything to talk to.
  security.polkit.enable = true;

  ## Qt + file manager without Plasma ######################################
  # Plan §31: Dolphin stays, but only the KDE pieces it genuinely needs are
  # installed — not the whole desktop. Without plasma-workspace, Dolphin
  # needs these explicitly:
  #   kio / kio-extras  — the protocol backends (trash:/, mtp:/, sftp:/…)
  #   qtwayland         — native Wayland windows instead of XWayland
  #   qtsvg             — SVG icon rendering (Papirus is SVG)
  #   kdegraphics-thumbnailers + ffmpegthumbs — file previews
  #   ark               — archive handling from the context menu
  # udisks2 + gvfs provide the removable-media mounting that Plasma's
  # device notifier used to handle.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  environment.systemPackages =
    (with pkgs; [
      hyprpolkitagent
      papirus-icon-theme
      wl-clipboard
    ])
    ++ (with pkgs.kdePackages; [
      dolphin
      kio
      kio-extras
      kdegraphics-thumbnailers
      ffmpegthumbs
      ark
      qtwayland
      qtsvg
    ]);

  programs.dconf.enable = true;
}
