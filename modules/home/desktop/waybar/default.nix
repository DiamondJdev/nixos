# Waybar — plan §16.
#
# Layout is three disconnected islands over a fully transparent bar. That is
# achieved by making `window#waybar` transparent and giving each of the three
# `.modules-*` containers its own background, border and radius, rather than
# by styling individual modules — which is what keeps the groups reading as
# three pills instead of eleven.
{
  pkgs,
  rice,
  ...
}:
let
  weather = import ./weather.nix { inherit pkgs rice; };
in
{
  home.packages = [ weather ];

  # The hand-written CSS below is the intentional custom styling plan §12
  # says to protect; Stylix's Waybar target would overwrite it.
  stylix.targets.waybar.enable = false;

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "hyprland-session.target" ];
    };

    settings.mainBar = {
      layer = "top";
      position = "top";
      # Height is left unset so the bar sizes to its content; a fixed height
      # fights the island padding and produces clipped borders.
      spacing = 0;
      margin-top = 6;
      margin-left = 10;
      margin-right = 10;

      modules-left = [ "hyprland/workspaces" ];
      modules-center = [
        "clock#date"
        "clock"
      ];
      modules-right = [
        "custom/weather"
        "cpu"
        "memory"
        "network"
        "bluetooth"
        "wireplumber"
        "custom/notification"
        "tray"
        "custom/power"
      ];

      ## Workspaces — plan §9 ##############################################
      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          # Plain numerals; the visual state (active/occupied/empty/urgent)
          # is carried by CSS rather than by swapping glyphs, so the row
          # stays a stable width as workspaces fill up.
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          "10" = "10";
        };
        # All ten are always shown (plan §9).
        persistent-workspaces."*" = 10;
        all-outputs = true;
        on-click = "activate";
        sort-by-number = true;
      };

      ## Clock / date #####################################################
      "clock#date" = {
        format = "{:%a %b %d}";
        tooltip = false;
      };
      "clock" = {
        format = "{:%H:%M}";
        # Plan §16: clicking the clock opens the notification centre, which
        # is where the calendar lives (SwayNC), rather than duplicating a
        # second calendar in a tooltip.
        on-click = "swaync-client -t -sw";
        tooltip-format = "<tt>{calendar}</tt>";
        calendar = {
          mode = "month";
          format = {
            months = "<span color='#${rice.palette.lavender}'><b>{}</b></span>";
            today = "<span color='#${rice.accent}'><b>{}</b></span>";
          };
        };
      };

      ## System ###########################################################
      "cpu" = {
        interval = 3;
        format = "  CPU {usage}%";
        tooltip = true;
        on-click = "alacritty -e btop";
      };
      "memory" = {
        interval = 5;
        format = "  RAM {percentage}%";
        tooltip-format = "{used:0.1f} GiB / {total:0.1f} GiB";
        on-click = "alacritty -e btop";
      };

      ## Network — plan §41 ###############################################
      "network" = {
        interval = 5;
        format-wifi = "  {signalStrength}%";
        format-ethernet = "󰈀";
        format-linked = "󰈀";
        format-disconnected = "󰤭";
        # Plan §41: do NOT expose credentials. Only interface, address and
        # link state appear here — never the PSK or the full connection
        # profile.
        tooltip-format-wifi = "{essid}\n{ifname}  {ipaddr}/{cidr}\n{bandwidthDownBits} ↓  {bandwidthUpBits} ↑";
        tooltip-format-ethernet = "{ifname}  {ipaddr}/{cidr}\n{bandwidthDownBits} ↓  {bandwidthUpBits} ↑";
        tooltip-format-disconnected = "Disconnected";
        on-click = "settings";
      };

      ## Bluetooth — plan §40 #############################################
      "bluetooth" = {
        format = "";
        format-disabled = "󰂲";
        format-off = "󰂲";
        format-connected = "  {num_connections}";
        tooltip-format = "{controller_alias}";
        tooltip-format-connected = "{controller_alias}\n\n{device_enumerate}";
        tooltip-format-enumerate-connected = "{device_alias}  {device_battery_percentage}%";
        on-click = "blueman-manager";
      };

      ## Audio — plan §39 #################################################
      # wireplumber rather than pulseaudio: it reports the real PipeWire
      # node, so the displayed volume matches what wpctl (and the media keys)
      # actually change.
      "wireplumber" = {
        format = "{icon}  {volume}%";
        format-muted = "󰝟";
        format-icons = [
          "󰕿"
          "󰖀"
          "󰕾"
        ];
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        # Plan §16: clicking volume should open audio controls.
        on-click-right = "pavucontrol";
        on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        tooltip-format = "{node_name}";
      };

      ## Weather — plan §17 ###############################################
      "custom/weather" = {
        exec = "${weather}/bin/waybar-weather";
        return-type = "json";
        interval = 1800; # 30 min; the script also caches for 25 min
        tooltip = true;
      };

      ## Notifications — plan §18 #########################################
      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='#${rice.palette.red}'><sup></sup></span>";
          none = "";
          dnd-notification = "<span foreground='#${rice.palette.red}'><sup></sup></span>";
          dnd-none = "";
          inhibited-notification = "<span foreground='#${rice.palette.red}'><sup></sup></span>";
          inhibited-none = "";
          dnd-inhibited-notification = "<span foreground='#${rice.palette.red}'><sup></sup></span>";
          dnd-inhibited-none = "";
        };
        return-type = "json";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw"; # toggle do-not-disturb
        escape = true;
      };

      "tray" = {
        icon-size = 16;
        spacing = 10;
      };

      ## Power — plan §23 #################################################
      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "power-menu";
      };
    };

    style = import ./style.nix { inherit rice; };
  };
}
