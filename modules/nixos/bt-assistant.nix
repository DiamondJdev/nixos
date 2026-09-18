# BT — voice-native assistant hub. App code lives in a standalone repo
# (~/Projects/bt-assistant); this module only wires up the pieces that need
# to be system-level: the local LLM backend it talks to, the service that
# runs it, and the secrets it needs.
#
# See ~/Projects/bt-assistant/DESIGN.md for the architecture and the
# decisions behind it (hybrid local/cloud routing, phase-1 scope, etc).
{ config, lib, pkgs, ... }:

let
  cfg = config.services.bt-assistant;
in
{
  options.services.bt-assistant = {
    enable = lib.mkEnableOption "BT voice assistant hub";

    projectDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/diamondjdev/Projects/bt-assistant";
      description = "Path to the bt-assistant application checkout.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "diamondjdev";
      description = "User the service runs as (needs audio device access).";
    };

    secretsFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/bt-assistant/secrets.env";
      description = ''
        systemd EnvironmentFile holding OPENAI_API_KEY. Created
        out-of-band (root:root, mode 600) — never stored in the nix store
        or the flake, since both are world-readable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # BT's local brain. Already scaffolded disabled elsewhere; this module
    # is the single place that turns it on so enabling BT is one flag.
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
    };

    systemd.services.bt-assistant = {
      description = "BT voice assistant";
      after = [ "network.target" "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        # `uv` resolves and runs against the project's own lockfile/venv;
        # keeps the app's Python deps out of the system closure.
        ExecStart = "${pkgs.uv}/bin/uv run bt";
        EnvironmentFile = "-${cfg.secretsFile}"; # '-' = optional, don't fail if absent
        Restart = "on-failure";
        RestartSec = "5s";

        # Sandboxing: real mic/speaker access needed, so this can't be
        # fully isolated, but keep it off the rest of the filesystem.
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.projectDir ];
        ProtectHome = "read-only";
        NoNewPrivileges = true;
      };
    };
  };
}
