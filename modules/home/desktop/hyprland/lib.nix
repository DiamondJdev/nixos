# Small helpers for emitting Home Manager's Lua-flavoured Hyprland settings.
#
# Home Manager renders `settings.<name>` as `hl.<name>(...)`, one call per
# list element, and only treats a value as raw Lua if it was built with
# `lib.generators.mkLuaInline`. Writing that out by hand at every call site
# is noisy and easy to get subtly wrong, so the shapes are named here once.
{ lib }:
rec {
  inline = lib.generators.mkLuaInline;

  # Lua string literal. toJSON gets the escaping right for quotes and
  # backslashes, and Lua's string escapes are a superset of JSON's for the
  # characters that actually occur in these commands.
  str = s: builtins.toJSON s;

  # hl.bind("<keys>", <dispatcher>)
  bind = keys: dispatcher: { _args = [ keys (inline dispatcher) ]; };

  # hl.bind("<keys>", <dispatcher>, { ...flags })
  bindWith = keys: dispatcher: flags: {
    _args = [
      keys
      (inline dispatcher)
      flags
    ];
  };

  # Dispatcher shorthands.
  exec = cmd: "hl.dsp.exec_cmd(${str cmd})";

  # hl.env("NAME", "value")
  env = name: value: { _args = [ name value ]; };

  # hl.curve("name", { ... })
  curve = name: spec: { _args = [ name spec ]; };

  # A bind repeated across workspaces 1..10. Workspace 10 lives on the `0`
  # key, which is why this is a helper rather than a plain `lib.range` map.
  perWorkspace =
    f:
    lib.concatMap (i: f i (toString (lib.mod i 10))) (lib.range 1 10);
}
