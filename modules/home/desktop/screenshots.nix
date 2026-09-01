# Screenshots — plan §32.
#
# Four flows, all through one Nix-built script so there is exactly one place
# that knows the pipeline. Plan §32 is explicit that scripts must live inside
# the Nix config rather than as ad-hoc files in the home directory.
#
#   Print               region  -> Satty (annotate)
#   SUPER+Print         region  -> clipboard
#   SHIFT+Print         full    -> clipboard
#   SUPER+SHIFT+Print   full    -> Satty (annotate)
{ pkgs, ... }:
let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [
      grim
      slurp
      satty
      wl-clipboard
      libnotify
      coreutils
      hyprland # for hyprctl, used to pick the focused output
    ];
    text = ''
      # Cancelling a selection must be silent. slurp exits non-zero when the
      # user presses Escape, and errexit would otherwise turn that ordinary
      # cancellation into a failed unit and an error notification — plan §32
      # requires that cancelling "does not leave errors".
      set +e

      DIR="''${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
      mkdir -p "$DIR"
      STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
      FILE="$DIR/screenshot_$STAMP.png"

      die_quietly() { exit 0; }

      grab_region() {
        geom=$(slurp -d -b '#1e1e2e66' -c '#cba6f7ff' -s '#cba6f71a' -w 2) || die_quietly
        [ -z "$geom" ] && die_quietly
        grim -g "$geom" "$1" || die_quietly
      }

      grab_full() {
        # Capture only the focused output rather than the whole layout.
        out=$(hyprctl monitors -j | grep -o '"name": *"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$out" ]; then
          grim -o "$out" "$1" || die_quietly
        else
          grim "$1" || die_quietly
        fi
      }

      to_clipboard() {
        wl-copy --type image/png < "$1"
        notify-send -i "$1" -a Screenshot "Screenshot copied" "Saved to $1"
      }

      edit() {
        # Satty writes the annotated result; --early-exit closes it as soon
        # as the user copies or saves.
        satty --filename "$1" \
              --output-filename "$1" \
              --early-exit \
              --initial-tool brush \
              --copy-command 'wl-copy --type image/png' \
          || die_quietly
        notify-send -i "$1" -a Screenshot "Screenshot saved" "$1"
      }

      case "''${1:-region-edit}" in
        region-edit)      grab_region "$FILE"; edit "$FILE" ;;
        region-clipboard) grab_region "$FILE"; to_clipboard "$FILE" ;;
        full-clipboard)   grab_full   "$FILE"; to_clipboard "$FILE" ;;
        full-edit)        grab_full   "$FILE"; edit "$FILE" ;;
        *)
          echo "usage: screenshot {region-edit|region-clipboard|full-clipboard|full-edit}" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [
    screenshot
    pkgs.grim
    pkgs.slurp
    pkgs.satty
    pkgs.wl-clipboard
    pkgs.libnotify
  ];

  # Give the saved files a predictable home and make it a real XDG dir.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
