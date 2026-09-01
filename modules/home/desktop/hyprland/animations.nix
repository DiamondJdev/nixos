# Animations — plan §15.
#
# Target: modern, restrained, and above all *fast*. Hyprland's `speed` is a
# duration in deciseconds (speed 2 ≈ 200 ms), so everything here sits in the
# 120–300 ms band the plan asks for. Springs are avoided entirely: their
# overshoot is exactly the "bouncy" quality the plan rules out, and on a
# 240 Hz panel the extra settle time is very visible.
{ hlib, ... }:
{
  config.animations.enabled = true;

  curve = [
    # Strong ease-out: fast departure, gentle arrival. The workhorse.
    (hlib.curve "easeOutQuint" {
      type = "bezier";
      points = [
        [ 0.23 1 ]
        [ 0.32 1 ]
      ];
    })
    # Symmetric, for things that move rather than appear.
    (hlib.curve "easeInOutCubic" {
      type = "bezier";
      points = [
        [ 0.65 0.05 ]
        [ 0.36 1 ]
      ];
    })
    # Near-instant with a soft tail — used for fades so they never linger.
    (hlib.curve "snap" {
      type = "bezier";
      points = [
        [ 0.15 0 ]
        [ 0.1 1 ]
      ];
    })
    (hlib.curve "linear" {
      type = "bezier";
      points = [
        [ 0 0 ]
        [ 1 1 ]
      ];
    })
  ];

  animation = [
    { leaf = "global"; enabled = true; speed = 3; bezier = "easeOutQuint"; }

    # Windows. "popin 92%" is a very shallow scale — present enough to read
    # as an animation, far short of the zoom effect the plan calls gimmicky.
    { leaf = "windows"; enabled = true; speed = 2.6; bezier = "easeOutQuint"; }
    { leaf = "windowsIn"; enabled = true; speed = 2.4; bezier = "easeOutQuint"; style = "popin 92%"; }
    { leaf = "windowsOut"; enabled = true; speed = 1.8; bezier = "snap"; style = "popin 94%"; }
    { leaf = "windowsMove"; enabled = true; speed = 2.2; bezier = "easeInOutCubic"; }

    # Border gradient rotation on focus change.
    { leaf = "border"; enabled = true; speed = 3.0; bezier = "easeOutQuint"; }

    { leaf = "fade"; enabled = true; speed = 2.0; bezier = "snap"; }
    { leaf = "fadeIn"; enabled = true; speed = 1.8; bezier = "snap"; }
    { leaf = "fadeOut"; enabled = true; speed = 1.5; bezier = "snap"; }

    # Layer surfaces: Waybar, SwayNC, Rofi, the dock. These appear and
    # disappear constantly, so they get the shortest durations of anything.
    { leaf = "layers"; enabled = true; speed = 2.0; bezier = "easeOutQuint"; }
    { leaf = "layersIn"; enabled = true; speed = 2.0; bezier = "easeOutQuint"; style = "fade"; }
    { leaf = "layersOut"; enabled = true; speed = 1.6; bezier = "snap"; style = "fade"; }

    # Workspace switching. A slide would be the obvious choice, but with
    # every window floating over a visible wallpaper a cross-fade reads far
    # more cleanly and costs less fill rate.
    { leaf = "workspaces"; enabled = true; speed = 2.2; bezier = "easeOutQuint"; style = "fade"; }
    { leaf = "workspacesIn"; enabled = true; speed = 2.2; bezier = "easeOutQuint"; style = "fade"; }
    { leaf = "workspacesOut"; enabled = true; speed = 2.0; bezier = "snap"; style = "fade"; }

    { leaf = "specialWorkspace"; enabled = true; speed = 2.2; bezier = "easeOutQuint"; style = "fade"; }
  ];
}
