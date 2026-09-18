# Keybindings — plan §8.
#
# Two rules shaped this map:
#   1. Predictable over clever (plan §8, closing line).
#   2. Don't break existing muscle memory without a reason. The bindings the
#      previous hand-written config already had (SUPER+Q terminal, SUPER+C
#      close, SUPER+E files, SUPER+R menu, SUPER+I settings, SUPER+M exit)
#      are preserved verbatim.
#
# Two deliberate departures from the old config, both required by the plan:
#   - SUPER+V was "toggle float"; plan §22 assigns it to clipboard history.
#     Float-toggle moves to SUPER+SHIFT+F. With everything floating by
#     default (plan §8) that toggle is now a rare operation, so it is the
#     cheaper of the two to relocate.
#   - SUPER+Space is added as a launcher binding alongside SUPER+R, since
#     plan §21 asks for one of Space/D. SUPER+R is kept so nothing is lost.
{
  lib,
  hlib,
  apps,
  ...
}:
let
  mod = "SUPER";
  inherit (hlib) bind bindWith exec perWorkspace;
in
{
  bind =
    [
      ## Applications ######################################################
      (bind "${mod} + Q" (exec apps.terminal))
      (bind "${mod} + E" (exec apps.fileManager))
      (bind "${mod} + I" (exec apps.settings)) # mirrors Windows' Win+I
      (bind "${mod} + R" (exec apps.launcher))
      (bind "${mod} + Space" (exec apps.launcher))
      (bind "${mod} + V" (exec apps.clipboard)) # plan §22
      (bind "${mod} + N" (exec apps.notificationCenter))
      (bind "${mod} + X" (exec apps.powerMenu))
      (bind "${mod} + L" (exec apps.lock))

      ## Window control ####################################################
      (bind "${mod} + C" "hl.dsp.window.close()")
      # Windows-style close, for the reflex everyone already has.
      (bind "ALT + F4" "hl.dsp.window.close()")
      (bind "${mod} + M" "hl.dsp.exit()")

      (bind "${mod} + F" ''hl.dsp.window.fullscreen({ mode = "fullscreen" })'')
      (bind "${mod} + SHIFT + M" ''hl.dsp.window.fullscreen({ mode = "maximized" })'')
      (bind "${mod} + SHIFT + F" ''hl.dsp.window.float({ action = "toggle" })'')
      (bind "${mod} + G" "hl.dsp.window.center()")
      (bind "${mod} + P" "hl.dsp.window.pseudo()")
      (bind "${mod} + J" ''hl.dsp.layout("togglesplit")'') # dwindle only

      ## Focus #############################################################
      (bind "${mod} + left" ''hl.dsp.focus({ direction = "left" })'')
      (bind "${mod} + right" ''hl.dsp.focus({ direction = "right" })'')
      (bind "${mod} + up" ''hl.dsp.focus({ direction = "up" })'')
      (bind "${mod} + down" ''hl.dsp.focus({ direction = "down" })'')

      ## Move window within the workspace ##################################
      (bind "${mod} + SHIFT + left" ''hl.dsp.window.move({ direction = "left" })'')
      (bind "${mod} + SHIFT + right" ''hl.dsp.window.move({ direction = "right" })'')
      (bind "${mod} + SHIFT + up" ''hl.dsp.window.move({ direction = "up" })'')
      (bind "${mod} + SHIFT + down" ''hl.dsp.window.move({ direction = "down" })'')

      ## Scratchpad ########################################################
      (bind "${mod} + S" ''hl.dsp.workspace.toggle_special("magic")'')
      (bind "${mod} + SHIFT + S" ''hl.dsp.window.move({ workspace = "special:magic" })'')

      ## Workspace scrolling ###############################################
      (bind "${mod} + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
      (bind "${mod} + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

      ## Mouse move / resize — plan §8 #####################################
      (bindWith "${mod} + mouse:272" "hl.dsp.window.drag()" { mouse = true; })
      (bindWith "${mod} + mouse:273" "hl.dsp.window.resize()" { mouse = true; })
      # Optional third mouse binding from plan §8: middle-click toggles
      # maximise, which is the most useful of the "maximize or floating"
      # options given windows already float.
      (bindWith "${mod} + mouse:274" ''hl.dsp.window.fullscreen({ mode = "maximized" })'' {
        mouse = true;
      })

      ## Screenshots — plan §32 ############################################
      (bind "Print" (exec apps.screenshotRegionEdit))
      (bind "${mod} + Print" (exec apps.screenshotRegionClipboard))
      (bind "SHIFT + Print" (exec apps.screenshotFullClipboard))
      (bind "${mod} + SHIFT + Print" (exec apps.screenshotFullEdit))

      ## Media / hardware keys #############################################
      # `locked` keeps these working while the session is locked, which is
      # the whole point of media keys; `repeating` lets volume ramp on hold.
      (bindWith "XF86AudioRaiseVolume" (exec "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") {
        locked = true;
      })
      (bindWith "XF86AudioMicMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") {
        locked = true;
      })
      (bindWith "XF86MonBrightnessUp" (exec "brightnessctl -e4 -n2 set 5%+") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86MonBrightnessDown" (exec "brightnessctl -e4 -n2 set 5%-") {
        locked = true;
        repeating = true;
      })

      (bindWith "XF86AudioNext" (exec "playerctl next") { locked = true; })
      (bindWith "XF86AudioPause" (exec "playerctl play-pause") { locked = true; })
      (bindWith "XF86AudioPlay" (exec "playerctl play-pause") { locked = true; })
      (bindWith "XF86AudioPrev" (exec "playerctl previous") { locked = true; })
    ]
    ## Workspaces 1..10 — plan §9 ##########################################
    # Workspace 10 sits on the `0` key, hence the modulo in hlib.perWorkspace.
    ++ perWorkspace (i: key: [
      (bind "${mod} + ${key}" "hl.dsp.focus({ workspace = ${toString i} })")
      (bind "${mod} + SHIFT + ${key}" "hl.dsp.window.move({ workspace = ${toString i} })")
    ]);

  ## Per-device input ######################################################
  # Per-device config for the real mouse (Razer Basilisk Ultimate). This
  # was previously a leftover template placeholder ("epic-mouse-v1", a
  # fake device name that never matched anything), so this mouse was
  # running fully raw/native sensitivity with no correction — the jump
  # in perceived sensitivity after moving off Plasma is KWin's own
  # pointer-speed compensation no longer applying, not a DPI change.
  # accel_profile "flat" disables acceleration entirely (1:1 raw input,
  # standard for gaming mice); sensitivity is the flat multiplier on top
  # of that, range -1.0 (slowest) to 1.0 (fastest). Tune to taste.
  # See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
  device = {
    name = "razer-razer-basilisk-ultimate-dongle";
    sensitivity = -0.5;
    accel_profile = "flat";
  };

  gesture = {
    fingers = 3;
    direction = "horizontal";
    action = "workspace";
  };
}
