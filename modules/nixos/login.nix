# SDDM login screen — plan §33.
#
# Plan §33 says that if a bespoke theme becomes fragile, start from a
# maintained one and customise it, and that the login screen must remain
# usable if visual assets fail. So rather than hand-writing QML, this builds
# on catppuccin-sddm, which already ships a `catppuccin-mocha-mauve` variant
# — the exact palette and accent this rice uses — and swaps in our wallpaper,
# fonts and avatar.
#
# The "usable if assets fail" requirement is met structurally: every
# customisation below is a *value* in theme.conf, not a change to the QML. If
# the background image were missing, the theme still renders (it falls back to
# its own solid colour) and the password field still works.
{
  pkgs,
  rice,
  ...
}:
let
  themeName = "catppuccin-mocha-mauve";
  wallName = builtins.baseNameOf rice.wallpaper.still;

  # The upstream theme with our wallpaper and typography substituted in.
  sddmTheme = pkgs.runCommand "sddm-theme-rice" { } ''
    mkdir -p "$out/share/sddm/themes"
    cp -r ${pkgs.catppuccin-sddm}/share/sddm/themes/${themeName} \
          "$out/share/sddm/themes/${themeName}"
    chmod -R u+w "$out/share/sddm/themes/${themeName}"

    # Same wallpaper as Hyprlock, so login and lock match (§33). The
    # original file name is preserved: QML's Image element uses the
    # extension to pick a decoder, so an extension-less copy can silently
    # fail to load.
    cp ${rice.wallpaper.still} \
       "$out/share/sddm/themes/${themeName}/backgrounds/${wallName}"

    cat > "$out/share/sddm/themes/${themeName}/theme.conf" <<EOF
    [General]
    Font="${rice.fonts.ui.name}"
    FontSize=11
    ClockEnabled="true"
    CustomBackground="true"
    LoginBackground="false"
    Background="backgrounds/${wallName}"
    UserIcon="true"
    PasswordShowLastLetter=0
    EOF
  '';
in
{
  services.displayManager.sddm = {
    theme = themeName;
    extraPackages = [ pkgs.catppuccin-sddm ];
    settings = {
      Theme.ThemeDir = "${sddmTheme}/share/sddm/themes";
      # Preselect the last user so the common case is just a password.
      Users.RememberLastUser = true;
      Users.RememberLastSession = true;
    };
  };

  # The theme's UserIcon reads the AccountsService avatar. A tmpfiles symlink
  # keeps this declarative — the alternative (copying into
  # /var/lib/AccountsService by hand) is exactly the mutable global state
  # plan §51.8 rules out.
  services.accounts-daemon.enable = true;
  systemd.tmpfiles.rules = [
    "d /var/lib/AccountsService/icons 0755 root root - -"
    "L+ /var/lib/AccountsService/icons/diamondjdev - - - - ${rice.profileImage}"
  ];

  # SDDM renders the greeter with Qt; without these it falls back to a
  # default sans and the theme's typography does not match Hyprlock's.
  fonts.packages = [ rice.fonts.ui.package ];
}
