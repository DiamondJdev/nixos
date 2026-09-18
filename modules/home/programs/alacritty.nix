# Alacritty — plan §27.
#
# Colours, font family and font size come from Stylix (which reads the same
# rice values), so this module only sets what Stylix does not: window
# geometry, padding, and the shell.
{ rice, ... }:
{
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        # Plan §27 asks for 0.88-0.94. Stylix also drives opacity from
        # stylix.opacity.terminal, which is set to the same rice value, so
        # the two agree rather than fighting.
        opacity = rice.opacity.terminal;
        padding = {
          x = 14;
          y = 12;
        };
        dynamic_padding = true;
        decorations = "None"; # plan §8: no title bars
        # Matches the default floating geometry so a new terminal lands at
        # a sensible size rather than the Alacritty default 80x24.
        dimensions = {
          columns = 110;
          lines = 30;
        };
      };

      scrolling.history = 20000;

      cursor = {
        style = {
          shape = "Block";
          blinking = "On";
        };
        blink_interval = 600;
      };

      # Zsh is the login shell (set in hosts/desktop/default.nix); naming it
      # here too means a terminal opened by a .desktop launcher — which does
      # not go through the login shell — still gets zsh.
      terminal.shell.program = "zsh";

      general.live_config_reload = true;
    };
  };
}
