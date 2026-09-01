# SwayNC CSS — plan §18.
#
# Matched to the Waybar islands: same base colour, same radii, same Mauve
# accent, same font. `ignore-gtk-theme` is not set, so these rules layer over
# the GTK theme; `cssPriority = "user"` in default.nix is what makes them win.
{ rice }:
let
  inherit (rice) palette accent radius fonts opacity;
  c = name: "#${palette.${name}}";
  panelBg = "rgba(30, 30, 46, ${toString opacity.notificationCenter})";
in
''
  /* Generated from settings.nix — do not hand-edit. */

  * {
    font-family: "${fonts.ui.name}", "${fonts.mono.name}";
    font-size: ${toString fonts.sizes.notification}px;
  }

  /* ---- Popup notifications ----------------------------------------- */
  .notification-row {
    outline: none;
    background: transparent;
  }

  .notification {
    border-radius: ${toString radius.panel}px;
    margin: 6px 10px;
    padding: 0;
    background: ${panelBg};
    border: 1px solid ${c "surface1"};
  }

  .notification-content {
    padding: 12px;
    border-radius: ${toString radius.panel}px;
  }

  .notification.critical {
    border: 1px solid ${c "red"};
  }

  .notification.low {
    border-color: ${c "surface0"};
  }

  .summary {
    color: ${c "text"};
    font-weight: 600;
    font-size: ${toString (fonts.sizes.notification + 1)}px;
  }

  .body {
    color: ${c "subtext0"};
  }

  .time {
    color: ${c "overlay1"};
    font-size: ${toString (fonts.sizes.notification - 1)}px;
  }

  .notification-action,
  .close-button {
    background: ${c "surface0"};
    color: ${c "text"};
    border: none;
    border-radius: ${toString radius.control}px;
    margin: 4px;
    padding: 4px 8px;
  }

  .notification-action:hover,
  .close-button:hover {
    background: ${rice.withHash accent};
    color: ${c "base"};
  }

  .notification-default-action:hover {
    background: rgba(203, 166, 247, 0.12);
  }

  /* Kill the stock drop shadow; Hyprland's own shadow + blur handle depth. */
  .notification-background,
  .control-center {
    box-shadow: none;
  }

  /* ---- Control centre ---------------------------------------------- */
  .control-center {
    background: ${panelBg};
    border: 1px solid ${rice.withHash accent};
    border-radius: ${toString radius.panel}px;
    padding: 12px;
  }

  .control-center-list {
    background: transparent;
  }

  .control-center-list-placeholder {
    color: ${c "overlay0"};
    opacity: 0.7;
  }

  /* ---- Title / clear-all ------------------------------------------- */
  .widget-title {
    color: ${c "text"};
    font-size: ${toString (fonts.sizes.notification + 4)}px;
    font-weight: 700;
    margin: 4px 6px 10px 6px;
  }

  .widget-title > button {
    background: ${c "surface0"};
    color: ${c "subtext1"};
    border: none;
    border-radius: ${toString radius.control}px;
    padding: 6px 12px;
    font-size: ${toString fonts.sizes.notification}px;
    font-weight: 500;
  }

  .widget-title > button:hover {
    background: ${c "red"};
    color: ${c "base"};
  }

  /* ---- Quick toggles ----------------------------------------------- */
  .widget-buttons-grid {
    background: rgba(49, 50, 68, 0.5);
    border-radius: ${toString radius.panel}px;
    padding: 8px;
    margin-bottom: 10px;
  }

  .widget-buttons-grid > flowbox > flowboxchild > button {
    background: ${c "surface0"};
    color: ${c "subtext1"};
    border: none;
    border-radius: ${toString radius.control}px;
    margin: 3px;
    padding: 10px;
    font-family: "${fonts.mono.name}";
    font-size: ${toString (fonts.sizes.notification + 4)}px;
    transition: background 150ms ease-out, color 150ms ease-out;
  }

  .widget-buttons-grid > flowbox > flowboxchild > button:hover {
    background: ${rice.withHash accent};
    color: ${c "base"};
  }

  /* ---- Sliders (volume + microphone) ------------------------------- */
  .widget-volume,
  .widget-slider {
    background: rgba(49, 50, 68, 0.5);
    border-radius: ${toString radius.panel}px;
    padding: 10px 12px;
    margin-bottom: 10px;
    color: ${c "text"};
  }

  .widget-volume > box > label,
  .widget-slider > label {
    color: ${rice.withHash accent};
    font-family: "${fonts.mono.name}";
    font-size: ${toString (fonts.sizes.notification + 3)}px;
    margin-right: 8px;
  }

  trough {
    background: ${c "surface2"};
    border-radius: 999px;
    min-height: 8px;
  }

  highlight {
    background: ${rice.withHash accent};
    border-radius: 999px;
    min-height: 8px;
  }

  slider {
    background: ${c "text"};
    border-radius: 999px;
    min-height: 14px;
    min-width: 14px;
    margin: -4px;
  }

  /* Per-app volume rows. */
  .per-app-volume {
    background: ${c "surface0"};
    border-radius: ${toString radius.control}px;
    padding: 4px 8px;
    margin: 4px 0;
  }

  /* ---- Media player ------------------------------------------------ */
  .widget-mpris {
    background: rgba(49, 50, 68, 0.5);
    border-radius: ${toString radius.panel}px;
    padding: 10px;
    margin-bottom: 10px;
  }

  .widget-mpris-player {
    background: transparent;
    padding: 4px;
  }

  .widget-mpris-title {
    color: ${c "text"};
    font-weight: 600;
    font-size: ${toString (fonts.sizes.notification + 1)}px;
  }

  .widget-mpris-subtitle {
    color: ${c "subtext0"};
    font-size: ${toString fonts.sizes.notification}px;
  }

  .widget-mpris > box > button {
    background: transparent;
    color: ${c "subtext1"};
    border: none;
    border-radius: ${toString radius.control}px;
    padding: 6px;
  }

  .widget-mpris > box > button:hover {
    background: rgba(203, 166, 247, 0.2);
    color: ${c "text"};
  }

  /* ---- Do not disturb ---------------------------------------------- */
  .widget-dnd {
    color: ${c "text"};
    margin-bottom: 8px;
  }

  .widget-dnd > switch {
    background: ${c "surface2"};
    border-radius: 999px;
    border: none;
  }

  .widget-dnd > switch:checked {
    background: ${rice.withHash accent};
  }

  .widget-dnd > switch slider {
    background: ${c "text"};
    border-radius: 999px;
  }
''
