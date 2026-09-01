# Clipboard history — plan §22.
#
# cliphist stores the history; Rofi is the frontend (plan §22 requires Rofi
# specifically, not cliphist's own picker). Bound to SUPER+V in
# hyprland/bindings.nix.
{ pkgs, ... }:
let
  # Named `clipboard-history` to match the `apps.clipboard` command in
  # hyprland/default.nix — the bindings never hardcode a store path.
  clipboard-history = pkgs.writeShellApplication {
    name = "clipboard-history";
    runtimeInputs = with pkgs; [
      cliphist
      rofi
      wl-clipboard
      gnused
    ];
    text = ''
      # cliphist's list format is "<id>\t<preview>". Rofi is told to display
      # only column 2 so the numeric id stays hidden but is still carried
      # through on selection, which is what `cliphist decode` needs.
      #
      # Images are stored as "[[ binary data ... ]]" preview rows; selecting
      # one decodes the real image bytes back onto the clipboard, so image
      # history works the same way text does.

      CLEAR_ENTRY="  Clear clipboard history"

      selection=$(
        {
          cliphist list
          printf '\t%s\n' "$CLEAR_ENTRY"
        } | rofi -dmenu \
              -display-columns 2 \
              -p "Clipboard" \
              -i \
              -no-custom
      ) || exit 0

      [ -z "$selection" ] && exit 0

      case "$selection" in
        *"$CLEAR_ENTRY")
          cliphist wipe
          notify-send "Clipboard" "History cleared" 2>/dev/null || true
          ;;
        *)
          printf '%s' "$selection" | cliphist decode | wl-copy
          ;;
      esac
    '';
  };
in
{
  services.cliphist = {
    enable = true;
    # Plan §22: persist image history too. This starts a second watcher for
    # the image mime types.
    allowImages = true;
    systemdTargets = [ "hyprland-session.target" ];
  };

  home.packages = [
    clipboard-history
    pkgs.wl-clipboard
  ];
}
