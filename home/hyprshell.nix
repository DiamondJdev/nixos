{ ... }:
{
  # Windows-style Alt-Tab window switcher for Hyprland.
  # Defaults already give ALT+Tab (modifier=Alt, key=Tab); the only
  # override needed is filter_by, since hyprshell defaults to
  # "current monitor only" — clearing it makes Alt-Tab cycle every
  # window across all workspaces and monitors.
  services.hyprshell = {
    enable = true;
    settings = {
      windows = {
        switch = {
          filter_by = [ ];
        };
      };
    };
  };
}
