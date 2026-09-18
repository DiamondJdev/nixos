# BT — voice-native assistant hub. App code lives in a standalone repo
# (~/Projects/bt-assistant); this module only wires up the pieces that need
# to be system-level
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

    # secretsFile = lib.mkOption {
    #   type = lib.types.path;
    #   default = "/etc/bt-assistant/secrets.env";
    #   description = ''
    #     systemd EnvironmentFile holding OPENAI_API_KEY. Created
    #     out-of-band (root:root, mode 600) — never stored in the nix store
    #     or the flake, since both are world-readable.
    #   '';
    # };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
      };
    };

    systemd.services.bt-assistant = {
      description = "BT voice assistant";
      after = [ "network.target" "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        UV_CACHE_DIR = "/var/cache/bt-assistant";
        # Expose numpy, onnxruntime and friends to systemd
        LD_LIBRARY_PATH = lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.zlib
          pkgs.portaudio
          pkgs.libsndfile
        ];
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = cfg.projectDir;
        ExecStart = "${pkgs.uv}/bin/uv run bt";
        Restart = "on-failure";
        RestartSec = "5s";

        # Sandboxing: real mic/speaker access needed, so this can't be
        # fully isolated, but keep it off the rest of the filesystem.
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.projectDir ];
        CacheDirectory = "bt-assistant";
        ProtectHome = "read-only";
        NoNewPrivileges = true;
      };
    };
  };
}
