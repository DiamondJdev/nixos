# wlogout CSS — plan §23.
#
# Visual target: fullscreen blurred wallpaper, dark overlay, five large
# actions in a row, the focused one highlighted in Mauve with a label below
# the icon.
{ rice, icons }:
let
  inherit (rice) palette accent radius fonts;
  c = name: "#${palette.${name}}";
in
''
  /* Generated from settings.nix — do not hand-edit. */

  * {
    background-image: none;
    box-shadow: none;
    font-family: "${fonts.ui.name}";
  }

  /* The dark overlay over the wallpaper. Hyprland's blur-power-menu layer
     rule blurs what is behind this, so the wallpaper shows through softened
     rather than sharp. */
  window {
    background-color: rgba(17, 17, 27, 0.75);
  }

  button {
    background-color: rgba(30, 30, 46, 0.72);
    border: 1px solid ${c "surface1"};
    border-radius: ${toString radius.panel}px;
    color: ${c "text"};
    font-size: 15px;
    font-weight: 500;

    background-repeat: no-repeat;
    background-position: center 32%;
    background-size: 22%;

    margin: 10px;
    /* Push the text clear of the icon so the label reads as sitting
       beneath it (plan §23: "labels below icons"). */
    padding-top: 34%;

    transition: background-color 150ms ease-out,
                border-color 150ms ease-out,
                color 150ms ease-out;
  }

  /* One active selection highlighted in Mauve — plan §23. Both :focus and
     :hover are styled so keyboard and mouse navigation look identical. */
  button:focus,
  button:hover {
    background-color: rgba(203, 166, 247, 0.18);
    border-color: ${rice.withHash accent};
    color: ${c "text"};
    outline: none;
  }

  button:active {
    background-color: rgba(203, 166, 247, 0.3);
  }

  #lock     { background-image: url("${icons}/lock.png"); }
  #logout   { background-image: url("${icons}/logout.png"); }
  #suspend  { background-image: url("${icons}/suspend.png"); }
  #reboot   { background-image: url("${icons}/reboot.png"); }
  #shutdown { background-image: url("${icons}/shutdown.png"); }

  /* Destructive actions pick up the warning accent on focus, so shutdown and
     reboot are visually distinct from the reversible ones. */
  #reboot:focus,
  #reboot:hover {
    border-color: ${c "peach"};
    background-color: rgba(250, 179, 135, 0.18);
  }

  #shutdown:focus,
  #shutdown:hover {
    border-color: ${c "red"};
    background-color: rgba(243, 139, 168, 0.18);
  }
''
