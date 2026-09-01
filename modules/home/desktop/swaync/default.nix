# SwayNC — notification daemon and control centre (plan §18).
#
# Replaces dunst, which was popup-only and had no history, no DND, no media
# controls and no panel.
#
# One deviation worth stating plainly: plan §18 lists a calendar in the
# control-centre panel, but SwayNC has no calendar widget (its widget set is
# title/dnd/label/mpris/buttons-grid/menubar/slider/volume/backlight/
# inhibitors/notifications). Rather than bolt on a fragile custom widget, the
# calendar lives in Waybar's clock tooltip — and clicking the clock opens
# this panel, so the two are one gesture apart.
{
  pkgs,
  rice,
  ...
}:
let
  # Toggle helpers. These need a shell for the conditional, so they are
  # packaged rather than inlined as bare command strings.
  toggleWifi = pkgs.writeShellScript "swaync-toggle-wifi" ''
    if [ "$(${pkgs.networkmanager}/bin/nmcli -t -f WIFI radio)" = "enabled" ]; then
      ${pkgs.networkmanager}/bin/nmcli radio wifi off
    else
      ${pkgs.networkmanager}/bin/nmcli radio wifi on
    fi
  '';

  toggleBluetooth = pkgs.writeShellScript "swaync-toggle-bluetooth" ''
    if ${pkgs.bluez}/bin/bluetoothctl show | grep -q "Powered: yes"; then
      ${pkgs.bluez}/bin/bluetoothctl power off
    else
      ${pkgs.bluez}/bin/bluetoothctl power on
    fi
  '';

  toggleMicMute = pkgs.writeShellScript "swaync-toggle-mic" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
  '';
in
{
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      layer-shell = true;

      # Give the hand-written CSS priority over the application default
      # stylesheet, otherwise only some rules land.
      cssPriority = "user";

      control-center-width = 420;
      control-center-height = 860;
      control-center-margin-top = 8;
      control-center-margin-right = 10;
      control-center-margin-bottom = 8;
      control-center-margin-left = 0;

      notification-window-width = 400;
      notification-icon-size = 48;
      notification-body-image-height = 160;
      notification-body-image-width = 200;
      notification-grouping = true;
      relative-timestamps = true;

      timeout = 8;
      timeout-low = 5;
      timeout-critical = 0; # critical notifications must be dismissed

      fit-to-screen = false;
      hide-on-clear = false;
      hide-on-action = true;
      image-visibility = "when-available";
      transition-time = 180; # matches the Hyprland animation band (§15)

      script-fail-notify = true;

      # Plan §18 panel structure, top to bottom.
      widgets = [
        "title"
        "dnd"
        "buttons-grid"
        "volume"
        "slider#mic"
        "mpris"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear all";
        };

        dnd.text = "Do not disturb";

        # Quick toggles — plan §18.
        "buttons-grid" = {
          actions = [
            {
              label = "Wi-Fi";
              command = "${toggleWifi}";
            }
            {
              label = "Bluetooth";
              command = "${toggleBluetooth}";
            }
            {
              label = "Mic";
              command = "${toggleMicMute}";
            }
            {
              label = "Audio";
              command = "${pkgs.pavucontrol}/bin/pavucontrol";
            }
            {
              label = "Devices";
              command = "${pkgs.blueman}/bin/blueman-manager";
            }
            {
              label = "Lock";
              command = "hyprlock";
            }
          ];
          buttons-per-row = 3;
        };

        volume = {
          label = "Volume";
          show-per-app = true;
          show-per-app-icon = true;
          expand-button-label = "More";
          collapse-button-label = "Less";
        };

        # Microphone. SwayNC's `volume` widget only drives the default sink,
        # so the input level is built from the generic slider widget wired
        # straight to wpctl. wpctl reports volume as "Volume: 0.55", hence
        # the awk field.
        "slider#mic" = {
          label = "Mic";
          min = 0;
          max = 1;
          cmd_getter = "${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gawk}/bin/awk '{print $2}'";
          cmd_setter = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SOURCE@ $value";
        };

        mpris = {
          image-size = 60;
          show-album-art = "always";
          loop-carousel = true;
          autohide = true;
        };

        notifications.vexpand = true;
      };
    };

    style = import ./style.nix { inherit rice; };
  };
}
