# Waybar CSS — plan §16.
#
# The island effect: the bar window itself is fully transparent, and each of
# the three `.modules-*` containers carries the background, border and radius.
# Hyprland blurs behind the bar via the `blur-bar` layer rule, and that rule's
# `ignore_alpha` is what stops the blur bleeding through the transparent gaps
# *between* the islands.
{ rice }:
let
  inherit (rice) palette accent radius fonts opacity;
  # Waybar's GTK CSS has no colour variables, so values are interpolated from
  # the same rice.palette every other module reads.
  c = name: "#${palette.${name}}";
  # Island fill: base colour at the configured bar opacity.
  islandBg = "rgba(30, 30, 46, ${toString opacity.bar})";
in
''
  /* Generated from settings.nix — do not hand-edit. */

  * {
    border: none;
    border-radius: 0;
    min-height: 0;
    font-family: "${fonts.ui.name}", "${fonts.mono.name}";
    font-size: ${toString fonts.sizes.bar}px;
    font-weight: 500;
  }

  /* Plan §16: fully transparent outer bar. */
  window#waybar {
    background: transparent;
  }

  /* The three islands. */
  .modules-left,
  .modules-center,
  .modules-right {
    background: ${islandBg};
    border: 1px solid ${c "surface1"};
    border-radius: ${toString radius.island}px;
    padding: 2px 6px;
    margin: 2px 0;
  }

  /* A thin accent hairline rather than a full-strength border — plan §11
     asks for thin borders, and a solid Mauve outline on all three groups
     reads as noise at this size. */
  .modules-center {
    border-color: ${c "surface2"};
  }

  #workspaces,
  #clock,
  #clock.date,
  #cpu,
  #memory,
  #network,
  #bluetooth,
  #wireplumber,
  #custom-weather,
  #custom-notification,
  #custom-power,
  #tray {
    background: transparent;
    color: ${c "text"};
    padding: 4px 10px;
  }

  /* ---- Workspaces — plan §9 ---------------------------------------- */
  #workspaces {
    padding: 2px 2px;
  }

  #workspaces button {
    background: transparent;
    color: ${c "overlay0"};
    padding: 2px 9px;
    margin: 2px 1px;
    border-radius: ${toString (radius.island - 4)}px;
    transition: background 150ms ease-out, color 150ms ease-out;
  }

  /* Occupied but not focused: brighter than empty, dimmer than active, so
     all three states are distinguishable at a glance (plan §9). */
  #workspaces button.occupied {
    color: ${c "subtext0"};
    background: rgba(69, 71, 90, 0.55);
  }

  #workspaces button.active {
    color: ${c "base"};
    background: ${rice.withHash accent};
  }

  #workspaces button.urgent {
    color: ${c "base"};
    background: ${c "red"};
  }

  #workspaces button:hover {
    background: rgba(203, 166, 247, 0.25);
    color: ${c "text"};
  }

  /* ---- Clock ------------------------------------------------------- */
  #clock {
    color: ${c "text"};
    font-weight: 600;
    padding-left: 4px;
  }

  #clock.date {
    color: ${c "subtext0"};
    font-weight: 500;
    padding-right: 4px;
  }

  /* ---- Right-hand indicators --------------------------------------- */
  /* Each indicator gets its own accent so the row is scannable by colour
     rather than by reading every glyph. */
  #cpu          { color: ${c "sapphire"}; }
  #memory       { color: ${c "lavender"}; }
  #network      { color: ${c "blue"}; }
  #bluetooth    { color: ${c "sky"}; }
  #wireplumber  { color: ${c "mauve"}; }
  #custom-weather { color: ${c "peach"}; }

  #network.disconnected,
  #bluetooth.off,
  #bluetooth.disabled {
    color: ${c "overlay0"};
  }

  #wireplumber.muted {
    color: ${c "overlay0"};
  }

  #custom-weather.weather-offline {
    color: ${c "overlay0"};
  }

  #custom-notification {
    color: ${c "text"};
    padding-right: 12px;
  }

  #custom-power {
    color: ${c "red"};
    padding: 4px 12px;
    margin-right: 2px;
    border-radius: ${toString (radius.island - 4)}px;
    transition: background 150ms ease-out;
  }

  #custom-power:hover {
    background: ${c "red"};
    color: ${c "base"};
  }

  #tray {
    padding-right: 6px;
  }

  #tray > .passive {
    -gtk-icon-effect: dim;
  }

  #tray > .needs-attention {
    -gtk-icon-effect: highlight;
  }

  /* ---- Tooltips ---------------------------------------------------- */
  tooltip {
    background: rgba(24, 24, 37, 0.96);
    border: 1px solid ${rice.withHash accent};
    border-radius: ${toString radius.control}px;
  }

  tooltip label {
    color: ${c "text"};
    font-family: "${fonts.mono.name}";
    padding: 4px;
  }
''
