# Look and feel — plan §14, §44.
#
# Every colour, radius and opacity here comes from ./settings.nix; nothing is
# a literal. Retheming happens there, not in this file.
{ rice, hlib, ... }:
let
  inherit (rice) palette opacity radius border accent accentAlt;
in
{
  config = {
    general = {
      gaps_in = border.gapsIn;
      gaps_out = border.gapsOut;
      border_size = border.size;

      col = {
        # A 45° Mauve→Lavender gradient on the focused window is the single
        # strongest accent cue in the design; inactive borders drop to a
        # muted surface tone so focus is unambiguous at a glance.
        active_border = {
          colors = [
            "rgba(${accent}ff)"
            "rgba(${accentAlt}ff)"
          ];
          angle = 45;
        };
        inactive_border = "rgba(${palette.surface0}aa)";
      };

      # This is a floating-first desktop (plan §8), so the border is a
      # primary resize affordance rather than decoration. Widening the grab
      # area makes it practical to hit without the SUPER modifier.
      resize_on_border = true;
      extend_border_grab_area = 12;
      hover_icon_on_border = true;

      # Floating windows get their own (larger) gap so they read as separate
      # cards over the wallpaper rather than as a tiled grid.
      float_gaps = border.gapsOut;

      # Edge/window snapping while dragging — the behaviour that makes a
      # floating WM feel like Windows/macOS instead of like loose sheets.
      snap = {
        enabled = true;
        window_gap = 8;
        monitor_gap = 8;
        border_overlap = false;
      };

      allow_tearing = false;
      layout = "dwindle";
    };

    decoration = {
      rounding = radius.window;
      rounding_power = 2;

      active_opacity = opacity.active;
      inactive_opacity = opacity.inactive;
      # Fullscreen windows go fully opaque: a transparent game or video is
      # both ugly and a waste of fill rate.
      fullscreen_opacity = 1.0;

      # Soft, wide, low-contrast shadow — plan §11 asks for soft shadows and
      # explicitly rules out a heavy glass look.
      shadow = {
        enabled = true;
        range = 20;
        render_power = 3;
        color = "rgba(0b0b12aa)";
        color_inactive = "rgba(0b0b1266)";
      };

      blur = {
        enabled = true;
        size = 6;
        passes = 3;
        # new_optimizations restricts blur to what is actually visible behind
        # a surface. With 3 passes at 240 Hz that is the difference between
        # comfortable and dropping frames, so it is not optional here.
        new_optimizations = true;
        xray = false;
        popups = true;
        popups_ignorealpha = 0.2;
        vibrancy = 0.18;
        vibrancy_darkness = 0.6;
        noise = 0.012;
        contrast = 1.05;
        brightness = 0.9;
      };

      # Plan §14 permits "slight inactive dimming if it looks clean". Kept
      # deliberately low so unfocused text stays readable — the opacity drop
      # is already doing most of the work.
      dim_inactive = true;
      dim_strength = 0.06;
      dim_around = 0.4; # used by dialogs that request it
    };

    # Ported from the (now disabled) Stylix Hyprland target, in the nested
    # form the Lua config actually accepts.
    group = {
      col = {
        border_active = "rgba(${accent}ff)";
        border_inactive = "rgba(${palette.surface0}aa)";
        border_locked_active = "rgba(${palette.sapphire}ff)";
      };
      groupbar = {
        text_color = "rgba(${palette.text}ff)";
        col = {
          active = "rgba(${accent}ff)";
          inactive = "rgba(${palette.surface0}aa)";
        };
      };
    };

    misc = {
      # Shown behind/between windows before the wallpaper daemon starts.
      background_color = "rgba(${palette.base}ff)";
      force_default_wallpaper = 0;
      disable_hyprland_logo = true;
      disable_splash_rendering = true;

      # Keep newly-opened floating windows fully on screen — with everything
      # floating, an off-screen spawn is a window the user cannot reach.
      new_float_force_onscreen = true;
      float_force_onscreen = true;

      focus_on_activate = true;
      animate_manual_resizes = false; # resizing should track the cursor 1:1
      vrr = 0; # fixed 240 Hz; VRR off avoids flicker on this panel
    };

    input = {
      kb_layout = "us";
      kb_variant = "";
      kb_model = "";
      kb_options = "";
      kb_rules = "";

      follow_mouse = 1;
      sensitivity = 0; # global; per-device tuning lives in settings.device
      numlock_by_default = true;

      touchpad.natural_scroll = false;
    };

    binds = {
      # Dragging a window by its middle rather than snapping the cursor to a
      # corner — matters much more when every window floats.
      drag_center_window = true;
      workspace_back_and_forth = false;
      allow_workspace_cycles = true;
    };

    cursor = {
      enable_hyprcursor = true;
      no_hardware_cursors = false;
      # Don't yank the pointer across the screen on workspace switches.
      warp_on_change_workspace = false;
    };

    dwindle = {
      # dwindle stays the nominal layout so that the rare tiled window (and
      # the special/scratchpad workspace) behaves sanely, but with the
      # float-everything rule in rules.nix it is seldom exercised.
      preserve_split = true;
      smart_resizing = true;
    };

    ecosystem = {
      no_donation_nag = true;
      no_update_news = true;
    };

    xwayland = {
      enabled = true;
      # Games and older Qt/GTK apps under XWayland look blurry when scaled;
      # at scale 1 this is a no-op but guards against future scaling.
      force_zero_scaling = true;
    };
  };
}
