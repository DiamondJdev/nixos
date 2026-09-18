# Hyprlock — lock screen (plan §24) — and the idle policy (plan §25).
#
# Composition, top to bottom, matching the plan's sketch:
#   Welcome back  /  clock  /  date  /  profile image  /  password box
# with the authentication-failure message rendered by the input field itself.
{
  pkgs,
  config,
  rice,
  ...
}:
let
  inherit (rice) palette accent fonts radius;
  hex = c: "rgb(${c})";
  hexa = c: a: "rgba(${c}${a})";
in
{
  # Stylix also defines settings.background (a unique-valued option, so the
  # definitions collide). Its version sets only a path and a fallback
  # colour; this module needs the blur/brightness treatment plan §24 calls
  # for, so it takes ownership — the wallpaper and palette both still come
  # from settings.nix, so nothing drifts.
  stylix.targets.hyprlock.enable = false;

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        # Don't run the PAM conversation on an empty submit — otherwise a
        # stray Enter counts as a failed attempt.
        ignore_empty_input = true;
        # If hyprlock somehow dies, the session must not be left unlocked.
        no_fade_in = false;
        grace = 0;
      };

      # Plan §24: blurred, darkened version of the main wallpaper. This reads
      # rice.wallpaper.still rather than .source, so it still works when the
      # live wallpaper is a video.
      background = [
        {
          path = "${rice.wallpaper.still}";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.011;
          contrast = 1.0;
          brightness = 0.4;
          vibrancy = 0.15;
        }
      ];

      # Profile image. If the file is missing hyprlock simply draws nothing
      # here — the lock screen stays usable, which plan §33 requires of the
      # login screen and is just as important here.
      image = [
        {
          path = "${rice.profileImage}";
          size = 120;
          rounding = -1; # -1 = fully circular
          border_size = 2;
          border_color = hex accent;
          position = "0, 20";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        # "Welcome back"
        {
          text = "Welcome back";
          color = hexa palette.subtext0 "cc";
          font_size = 16;
          font_family = fonts.ui.name;
          position = "0, 330";
          halign = "center";
          valign = "center";
        }
        # Clock
        {
          text = ''cmd[update:1000] date +"%H:%M"'';
          color = hex palette.text;
          font_size = fonts.sizes.lockClock;
          font_family = "${fonts.ui.name} Bold";
          position = "0, 240";
          halign = "center";
          valign = "center";
        }
        # Date
        {
          text = ''cmd[update:60000] date +"%A, %B %-d"'';
          color = hexa palette.subtext1 "dd";
          font_size = fonts.sizes.lockDate;
          font_family = fonts.ui.name;
          position = "0, 165";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          size = "300, 50";
          outline_thickness = 2;
          dots_size = 0.26;
          dots_spacing = 0.3;
          dots_center = true;
          rounding = radius.panel;

          outer_color = hexa palette.surface1 "cc";
          inner_color = hexa palette.base "cc";
          font_color = hex palette.text;
          font_family = fonts.ui.name;

          # Accent while typing, red on failure — the visible failure state
          # plan §24 asks for.
          check_color = hex accent;
          fail_color = hex palette.red;

          placeholder_text = ''<span foreground="##${palette.overlay1}">Password</span>'';
          fail_text = "<i>Authentication failed ($ATTEMPTS)</i>";

          position = "0, -110";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  ## Idle policy — plan §25 ################################################
  # The plan is emphatic: NO automatic lock, dim, DPMS-off or suspend. So
  # hypridle runs with an empty `listener` list — it is present only for the
  # two event-driven hooks below, which are exactly the "optional safety
  # behaviour" §25 permits:
  #   before_sleep_cmd — lock before the machine actually suspends
  #   lock_cmd         — makes `loginctl lock-session` reach hyprlock, which
  #                      is what the wlogout suspend action and any other
  #                      logind lock request go through
  # Adding a `listener` block here would violate §25.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "${pkgs.procps}/bin/pidof hyprlock || ${config.programs.hyprlock.package}/bin/hyprlock";
        before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
        # Bare `hyprctl`, not ${pkgs.hyprland}: a store path here would pull
        # nixpkgs' Hyprland (0.55.4) into the closure alongside the flake's
        # 0.56.0 — exactly the version mixing plan §6 warns about. hypridle
        # runs inside the session, so PATH already has the correct hyprctl.
        after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ state = \"on\" })'";
      };
      listener = [ ];
    };
  };
}
