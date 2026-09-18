# nwg-dock CSS — plan §20: rounded pill, dark translucent, Mauve accent.
{ rice }:
let
  inherit (rice) palette accent radius opacity;
  c = name: "#${palette.${name}}";
in
''
  /* Generated from settings.nix — do not hand-edit. */

  window {
    background: rgba(30, 30, 46, ${toString opacity.bar});
    border: 1px solid ${c "surface1"};
    /* A generous radius is what makes the dock read as a pill rather than
       a bar (§20). */
    border-radius: ${toString (radius.panel + 8)}px;
    padding: 6px 10px;
  }

  #box {
    background: transparent;
    padding: 2px;
  }

  button {
    background: transparent;
    border: none;
    border-radius: ${toString radius.control}px;
    margin: 0 3px;
    padding: 6px;
    transition: background 150ms ease-out;
  }

  button:hover {
    background: rgba(203, 166, 247, 0.22);
  }

  /* The running-application indicator dot under each icon. */
  #active {
    background: ${rice.withHash accent};
    border-radius: 999px;
    min-height: 3px;
    margin: 2px 8px 0 8px;
  }

  #inactive {
    background: transparent;
    min-height: 3px;
    margin: 2px 8px 0 8px;
  }

  tooltip {
    background: rgba(24, 24, 37, 0.96);
    border: 1px solid ${rice.withHash accent};
    border-radius: ${toString radius.control}px;
  }

  tooltip label {
    color: ${c "text"};
    padding: 4px;
  }
''
