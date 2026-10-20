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
      description = ''
        User the service runs as. Kept as the checkout's owner (rather than a
        dedicated system user) so the home-directory checkout stays readable
        without extra ACLs. The production voice pipeline streams audio over
        a WebSocket from the browser client — it never touches server-side
        mic/speaker hardware — so this is purely a file-ownership
        convenience, not a hardware-access requirement.
      '';
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
        # Deployment topology, pinned here so it's visible without reading
        # the gitignored .env in the checkout. Provider/model choice
        # (BT_OLLAMA_MODEL, OPENAI_API_KEY, BT_WHISPER_*, ...) stays in
        # .env — load_dotenv(override=False) won't touch what's set here.
        BT_HOST = "127.0.0.1";
        BT_DB_PATH = "/var/lib/bt-assistant/bt.sqlite3";

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
        WorkingDirectory = cfg.projectDir;
        # Run the pre-synced .venv directly rather than `uv run bt`: avoids
        # re-resolving the environment (and depending on network/PyPI
        # reachability) on every start, including every Restart=on-failure
        # retry. Upgrades are `uv sync` while the service is stopped, same
        # as the project's own deployment docs describe.
        ExecStart = "${cfg.projectDir}/.venv/bin/bt";
        # NLTK refuses hardlinked files (store optimisation hardlinks them), so copy instead of pointing at the store.
        ExecStartPre = "${pkgs.coreutils}/bin/cp -rT --no-preserve=mode ${pkgs.nltk-data.punkt-tab} /var/cache/bt-assistant/nltk_data";
        Restart = "on-failure";
        RestartSec = "5s";
        # Whisper/Silero/openwakeword model loading on a cold cache is slow;
        # the systemd default (90s) can kill a healthy first start.
        TimeoutStartSec = "300s";
        TimeoutStopSec = "45s";

        # Sandboxing: real mic/speaker access is not needed (voice audio
        # comes over the browser WebSocket), so this can be fully isolated
        # from the rest of $HOME. Only the checkout itself is exposed.
        ProtectSystem = "strict";
        # true makes /home inaccessible, which ReadWritePaths cannot undo, so the
        # .venv ExecStart was not found (203/EXEC). tmpfs + BindPaths exposes only the checkout.
        ProtectHome = "tmpfs";
        BindPaths = [ cfg.projectDir ];
        ReadWritePaths = [ cfg.projectDir ];
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
