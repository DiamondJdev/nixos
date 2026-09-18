# Window, layer and workspace rules — plan §8, §10, §44.
#
# ORDER IS SIGNIFICANT. Hyprland applies rules in declaration order and a
# later rule overrides an earlier one, so this file reads as a cascade:
# broad defaults first, then progressively narrower exceptions.
{
  lib,
  rice,
  ...
}:
let
  inherit (rice) monitor floating palette opacity;

  # Derived from the centralised monitor + percentage rather than hardcoded,
  # so changing the panel or the percentage in settings.nix is enough.
  defaultW = monitor.width * floating.widthPct / 100;
  defaultH = monitor.height * floating.heightPct / 100;
  defaultGeom = "${toString defaultW} ${toString defaultH}";

  # Applications whose natural size is much smaller than 70% of the screen.
  # Forcing the default geometry on these looks absurd (a volume mixer the
  # size of a browser), so they get a compact size instead.
  compactApps = "^(org.pulseaudio.pavucontrol|pavucontrol|blueman-manager|nm-connection-editor|org.gnome.Calculator)$";

  # Games. Hyprland *does* have a `content = "game"` matcher, but it relies
  # on the client opting in via wp_content_type_v1 — which Proton/XWayland
  # titles essentially never do. So class matching carries the weight here
  # and `content` is a bonus signal, not the mechanism.
  gameClasses = "^(steam_app_[0-9]+|gamescope|.*\\.exe|hl2_linux|Minecraft.*)$";
in
{
  window_rule = [
    ## 1. Global defaults ###################################################
    {
      # Ignore maximize requests from all apps. Applications that maximize
      # themselves on launch would otherwise defeat the floating geometry
      # below on every start.
      name = "suppress-maximize-events";
      match.class = ".*";
      suppress_event = "maximize";
    }
    {
      # Plan §8: normal application windows float.
      name = "float-by-default";
      match.class = ".*";
      float = true;
    }
    {
      # Plan §8: ~70% width, centred. Restricted to non-modal windows so
      # that dialogs, file pickers and other transients keep the size they
      # asked for — the plan explicitly calls this out. `modal` is a real
      # Hyprland matcher (RULE_PROP_MODAL), which is what makes this
      # expressible without regex gymnastics.
      name = "default-floating-geometry";
      match = {
        class = ".*";
        modal = false;
      };
      size = defaultGeom;
    }
    {
      name = "center-new-windows";
      match.class = ".*";
      center = true;
    }
    {
      # Remember a window's size after the user resizes it, instead of
      # snapping back to the default on the next launch.
      name = "remember-user-size";
      match.class = ".*";
      persistent_size = true;
    }

    ## 2. Compatibility fixes ##############################################
    {
      # Fix some dragging issues with XWayland.
      name = "fix-xwayland-drags";
      match = {
        class = "^$";
        title = "^$";
        xwayland = true;
        float = true;
        fullscreen = false;
        pin = false;
      };
      no_focus = true;
    }

    ## 3. Size exceptions ##################################################
    {
      name = "compact-utilities";
      match.class = compactApps;
      size = "900 620";
    }
    {
      # Picture-in-picture should be a small always-on-top overlay, never a
      # 70%-width window.
      name = "picture-in-picture";
      match.title = "^(Picture-in-Picture|Picture in picture)$";
      size = "640 360";
      pin = true;
      move = "monitor_w-680 monitor_h-420";
      no_blur = true;
    }

    ## 4. Games — plan §10 #################################################
    {
      # Games and similar fullscreen applications maximise automatically.
      # `content` is matched separately below since most games never set it.
      name = "games-fullscreen";
      match.initial_class = gameClasses;
      fullscreen = true;
    }
    {
      name = "games-content-hint-fullscreen";
      match.content = "game";
      fullscreen = true;
    }
    {
      # Effects are pure overhead behind an opaque fullscreen game, and blur
      # in particular is expensive. Disabling them per-rule (rather than
      # globally toggling the compositor) is the reversible approach plan
      # §45 asks for: nothing has to be restored when the game exits, because
      # nothing global was changed.
      name = "games-no-effects";
      match = {
        initial_class = gameClasses;
        fullscreen = true;
      };
      no_blur = true;
      no_shadow = true;
      no_anim = true;
      no_dim = true;
      opaque = true;
      immediate = true; # allow tearing for input latency
      idle_inhibit = "fullscreen";
    }
    {
      # Plan §10: do NOT aggressively fullscreen Steam itself. This rule
      # exists specifically to undo the game rules for Steam's own windows,
      # which is why it comes after them.
      name = "steam-client-stays-windowed";
      match.class = "^[Ss]team$";
      fullscreen = false;
      float = true;
      size = defaultGeom;
    }
    {
      # Steam's transient popups (friends list, tooltips, notifications)
      # report the same class but should keep their own geometry.
      name = "steam-popups-keep-size";
      match = {
        class = "^[Ss]team$";
        title = "negative:^Steam$";
      };
      center = false;
    }

    ## 5. Readability — plan §44 ###########################################
    {
      # Dense-reading surfaces stay closer to opaque than the global default.
      name = "readable-opacity";
      match.class = "^(code|Code|dev\\.zed\\.Zed|zen-beta|zen|firefox|obsidian)$";
      opacity = "${toString opacity.active} ${toString opacity.inactive}";
    }
  ];

  ## Layer rules — plan §16, §44 ###########################################
  # These are what actually put blur *behind* the bar, launcher and control
  # centre. `ignore_alpha` stops the blur bleeding through the fully
  # transparent parts of a layer (critical for Waybar, whose outer surface is
  # transparent and would otherwise render as one big blurred slab instead of
  # discrete islands).
  layer_rule = [
    {
      name = "blur-bar";
      match.namespace = "^waybar$";
      blur = true;
      ignore_alpha = 0.35;
      xray = false;
    }
    {
      name = "blur-launcher";
      match.namespace = "^rofi$";
      blur = true;
      ignore_alpha = 0.2;
    }
    {
      name = "blur-notifications";
      match.namespace = "^swaync-(control-center|notification-window)$";
      blur = true;
      ignore_alpha = 0.2;
    }
    {
      name = "blur-dock";
      match.namespace = "^nwg-dock$";
      blur = true;
      ignore_alpha = 0.35;
    }
    {
      name = "blur-power-menu";
      match.namespace = "^wlogout$";
      blur = true;
      ignore_alpha = 0.1;
    }
    {
      # The wallpaper layer must never be blurred — it is the thing
      # everything else is blurring *against*.
      name = "wallpaper-no-blur";
      match.namespace = "^(awww-daemon|swww-daemon|mpvpaper|wallpaper)$";
      blur = false;
      no_anim = true;
      order = -1;
    }
  ];

  ## Workspace rules — plan §9 #############################################
  # All ten workspaces exist on the single monitor. Waybar renders them as
  # persistent regardless (see the waybar module); this just pins them to the
  # output so their identity is stable.
  workspace_rule = lib.map (i: {
    workspace = toString i;
    monitor = monitor.output;
    default = i == 1;
  }) (lib.range 1 10);
}
