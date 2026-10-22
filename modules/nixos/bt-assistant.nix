# BT — voice-native assistant hub. App code lives in a standalone repo
# (~/Projects/bt-assistant); this module only wires up the pieces that need
# to be system-level.
#
# That repo is now a monorepo: the Python backend sits in server/ alongside
# the planned apple/ and editors/ clients, so projectDir is the checkout root
# and serverDir is the backend within it.
#
# Production runs from /var/lib/bt-deploy/current, a release that bt-deploy
# built and tested from main. ~/Projects/bt-assistant is the dev checkout only.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.bt-assistant;
  # pyproject.toml/uv.lock live here, so this is also where `uv sync` puts .venv.
  serverDir = "${cfg.projectDir}/server";
in
{
  options.services.bt-assistant = {
    enable = lib.mkEnableOption "BT voice assistant hub";

    projectDir = lib.mkOption {
      type = lib.types.path;
      default = "/home/diamondjdev/Projects/bt-assistant";
      description = ''
        Path to the bt-assistant monorepo checkout (the repository root, not
        the server/ subdirectory the backend runs from).
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "diamondjdev";
      description = ''
        User the service runs as. Kept as the checkout's owner (rather than a
        dedicated system user) so the home-directory checkout stays readable
        without extra ACLs. The production voice pipeline streams audio over
        a WebSocket from the browser client — it never touches server-side
        mic/speaker hardware — so this is purely a file-ownership
        convenience, not a hardware-access requirement.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        # 4096 overflowed long voice sessions (~2.3k-token prompt); 8192 still leaves ~1.6 GiB VRAM free on the 7800 XT.
        OLLAMA_CONTEXT_LENGTH = "8192";
      };
    };

    systemd.services.bt-assistant = {
      description = "BT voice assistant";
      after = [ "network.target" "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];

      # faster-whisper/piper/openwakeword need this to shell out for
      # non-PCM container/codec handling in the browser audio path.
      path = with pkgs; [ ffmpeg ];

      environment = {
        # Deployment topology, pinned here. Provider/model choice
        # (BT_OLLAMA_MODEL, OPENAI_API_KEY, BT_WHISPER_*, ...) comes from
        # EnvironmentFile below; a release built from git has no .env.
        BT_HOST = "127.0.0.1";
        BT_DB_PATH = "/var/lib/bt-assistant/bt.sqlite3";
        # Also pinned out of the checkout, for the same reason as BT_DB_PATH:
        # the default ("memory") is resolved against the working directory, so
        # it would otherwise have followed the backend into server/ and
        # orphaned the existing notes.
        BT_MEMORY_DIR = "/var/lib/bt-assistant/memory";

        # Model assets (Whisper, Silero VAD, openwakeword) must land under
        # a writable cache now that ProtectHome=true hides the rest of
        # $HOME — otherwise first-run/model-change downloads fail closed.
        XDG_CACHE_HOME = "/var/cache/bt-assistant";
        HF_HOME = "/var/cache/bt-assistant/huggingface";
        # Pipecat sentence-splits LLM text with NLTK punkt_tab; ~/nltk_data is hidden by ProtectHome.
        NLTK_DATA = "/var/cache/bt-assistant/nltk_data";

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
        WorkingDirectory = serverDir;
        # Run the pre-synced .venv directly rather than `uv run bt`: avoids
        # re-resolving the environment (and depending on network/PyPI
        # reachability) on every start, including every Restart=on-failure
        # retry. Upgrades are `uv sync` while the service is stopped, same
        # as the project's own deployment docs describe.
        ExecStart = "${serverDir}/.venv/bin/bt";
        # NLTK refuses hardlinked files (store optimisation hardlinks them), so copy instead of pointing at the store.
        ExecStartPre = "${pkgs.coreutils}/bin/cp -rT --no-preserve=mode ${pkgs.nltk-data.punkt-tab} /var/cache/bt-assistant/nltk_data";
        Restart = "on-failure";
        RestartSec = "5s";
        # Whisper/Silero/openwakeword model loading on a cold cache is slow;
        # the systemd default (90s) can kill a healthy first start.
        TimeoutStartSec = "300s";
        TimeoutStopSec = "45s";

        # Provider settings and secrets: root:root 0600, created by hand, never
        # in the store. Required: starting without the model settings is worse
        # than not starting. It overrides `environment`, so keep topology
        # (BT_HOST, BT_DB_PATH, BT_MEMORY_DIR) out of it.
        EnvironmentFile = "/etc/bt-assistant/bt.env";

        # Sandboxing: real mic/speaker access is not needed (voice audio
        # comes over the browser WebSocket), so $HOME stays hidden. The code
        # under /var/lib/bt-deploy is read-only here (ProtectSystem=strict);
        # only the state and cache directories below are writable. Don't
        # bind-mount `current`: it's a symlink, and a bind would pin the
        # release that was live at boot.
        ProtectSystem = "strict";
        ProtectHome = "tmpfs";
        StateDirectory = "bt-assistant";
        StateDirectoryMode = "0700";
        CacheDirectory = "bt-assistant";
        CacheDirectoryMode = "0700";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
