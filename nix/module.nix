self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.silo-server;
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    literalExpression
    optionalAttrs
    ;
in
{
  options.services.silo-server = {
    enable = mkEnableOption "Silo, a self-hosted Jellyfin-compatible media server";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = literalExpression "silo-server.packages.\${system}.default";
      description = "The silo-server package to run.";
    };

    user = mkOption {
      type = types.str;
      default = "silo-server";
      description = "User account under which Silo runs.";
    };

    group = mkOption {
      type = types.str;
      default = "silo-server";
      description = "Group under which Silo runs.";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/silo-server";
      description = ''
        Directory used for Silo's own working/plugin-cache state. This is
        distinct from your media library and from the database, which
        Silo does not store here.
      '';
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          DATABASE_URL = "postgres://silo:silo@127.0.0.1:5432/silo";
          REDIS_URL = "redis://127.0.0.1:6379";
          PORT = "8080";
        }
      '';
      description = ''
        Non-secret environment variables passed to Silo. See upstream's
        `.env.example` for the full list — `DATABASE_URL`, `REDIS_URL`,
        `PORT`, `JF_PORT`, `SILO_PUBLIC_URL`, etc.

        `DATABASE_URL` is required; Silo does not manage a database for
        you (PostgreSQL 18+ with the `pgvector` extension is required).
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to an EnvironmentFile (e.g. produced by sops-nix or agenix)
        providing at least `SECRET_KEY`, Silo's at-rest credential
        encryption key. Silo refuses to start without it, and losing it
        makes every encrypted secret in the database unrecoverable —
        back it up separately from database dumps.

        Values set here take precedence over
        {option}`services.silo-server.environment`.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Open {option}`services.silo-server.port` in the firewall. Ports
        for optional compat listeners (Jellyfin-compat via `JF_PORT`,
        audiobookshelf-compat) are not managed by this module — open
        those yourself if you enable them.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = ''
        Main HTTP port. This only controls firewall bookkeeping when
        {option}`services.silo-server.openFirewall` is set — to actually
        change the port Silo listens on, set `PORT` via
        {option}`services.silo-server.environment`.
      '';
    };
  };

  config = mkIf cfg.enable {
    users.groups.${cfg.group} = { };
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.silo-server = {
      description = "Silo media server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = cfg.environment;
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${cfg.package}/bin/silo";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.dataDir ];
        PrivateTmp = true;
      } // optionalAttrs (cfg.environmentFile != null) {
        EnvironmentFile = cfg.environmentFile;
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];
  };
}
