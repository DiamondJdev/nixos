# bt-deploy: deploys bt-assistant from its git branch. A timer fetches the
# branch, builds and tests each new commit under /var/lib/bt-deploy/releases,
# switches the `current` symlink the service runs from, and rolls back if
# /ready doesn't answer. `bt-deploy status|now|log` is the owner's view.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.bt-deploy;
  bt = config.services.bt-assistant;
  btEnv = config.systemd.services.bt-assistant.environment;
  stateDir = "/var/lib/bt-deploy";

  env = {
    BT_DEPLOY_STATE = stateDir;
    BT_DEPLOY_REPO_URL = cfg.repoUrl;
    BT_DEPLOY_BRANCH = cfg.branch;
    BT_DEPLOY_USER = bt.user;
    BT_DEPLOY_SERVICE = "bt-assistant.service";
    BT_DEPLOY_READY_URL = "http://127.0.0.1:8080/ready";
    BT_DEPLOY_READY_TIMEOUT = toString cfg.readyTimeout;
    BT_DEPLOY_DB = btEnv.BT_DB_PATH;
    # Never `uv run pytest`: see the .pth note in bt-assistant's AGENTS.md.
    BT_DEPLOY_CHECK = "uv sync --frozen --python ${pkgs.python311}/bin/python3.11 --no-python-downloads && .venv/bin/python -m pytest -q";
  };

  script = pkgs.writeShellApplication {
    name = "bt-deploy";
    runtimeInputs = with pkgs; [ git gnutar coreutils gawk curl sqlite util-linux systemd uv python311 ];
    # writeShellApplication adds its own shebang; a second one fails shellcheck.
    text = lib.removePrefix "#!/usr/bin/env bash\n" (builtins.readFile ./bt-deploy.sh);
  };

  # Same settings for the owner's `bt-deploy status` over SSH.
  wrapped = pkgs.symlinkJoin {
    name = "bt-deploy";
    paths = [ script ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = "wrapProgram $out/bin/bt-deploy "
      + lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "--set ${k} ${lib.escapeShellArg v}") env);
  };
in
{
  options.services.bt-deploy = {
    enable = lib.mkEnableOption "automatic bt-assistant deploys from git";

    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/DiamondJdev/bt-assistant.git";
      description = "Public HTTPS URL of the bt-assistant repository.";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Branch to deploy.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "2min";
      description = "Time between the end of one check and the start of the next.";
    };

    readyTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 180;
      description = "Seconds to wait for /ready after a restart before rolling back.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.bt-assistant.projectDir = "${stateDir}/current";

    environment.systemPackages = [ wrapped ];

    # `bt-deploy status|log` read the journal without sudo.
    users.users.${bt.user}.extraGroups = [ "systemd-journal" ];

    # `bt-deploy now` starts the unit without sudo, and nothing else.
    security.polkit.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "bt-deploy.service" &&
            action.lookup("verb") == "start" &&
            subject.user == "${bt.user}") {
          return polkit.Result.YES;
        }
      });
    '';

    systemd.services.bt-deploy = {
      description = "Deploy bt-assistant from ${cfg.branch}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = env // {
        # The tests import numpy and onnxruntime.
        LD_LIBRARY_PATH = btEnv.LD_LIBRARY_PATH;
        # runuser doesn't give uv a usable cache dir; run creates and chowns this.
        UV_CACHE_DIR = "${stateDir}/uv-cache";
      };
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}/bin/bt-deploy run";
        SyslogIdentifier = "bt-deploy";
        StateDirectory = "bt-deploy";
        StateDirectoryMode = "0755";
        TimeoutStartSec = "30min";
      };
    };

    systemd.timers.bt-deploy = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitInactiveSec = cfg.interval;
      };
    };
  };
}
