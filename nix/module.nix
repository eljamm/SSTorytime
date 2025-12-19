{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    types
    ;

  cfg = config.services.sstorytime;

  dbName = "sstoryline";
  localDB = cfg.database.createLocally;
in
{
  options.services.sstorytime = {
    enable = mkEnableOption "SSTorytime";
    package = mkPackageOption pkgs "sstorytime" { };

    port = mkOption {
      type = types.port;
      description = "Port for the SSTorytime service.";
      default = 8080;
    };

    openFirewall = mkEnableOption "the default ports in the firewall for the SSTorytime server.";

    user = mkOption {
      type = types.nonEmptyStr;
      default = "sstorytime";
      description = "User account under which SSTorytime runs.";
    };

    group = mkOption {
      type = types.nonEmptyStr;
      default = "sstorytime";
      description = "Group under which SSTorytime runs.";
    };

    database = {
      createLocally = mkEnableOption "configure a local PostgreSQL database for SSTorytime.";

      host = mkOption {
        type = types.str;
        default = "/var/run/postgresql";
        example = "192.168.23.42";
        description = "Database host address or unix socket.";
      };

      port = mkOption {
        type = with types; nullOr port;
        default = if localDB then null else 5432;
        defaultText = lib.literalExpression ''
          if `config.services.sstorytime.database.host` is `localhost` or `/run/postgresql`
          then null
          else 5432
        '';
        description = "Database host port.";
      };

      dbname = mkOption {
        type = types.str;
        default = "sstoryline";
        description = "Database name.";
      };

      user = mkOption {
        type = types.str;
        default = "sstoryline";
        description = "Database user.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/run/secrets/db-password";
        description = ''
          Path to a file containing the PostgreSQL password for
          {option}`database.user`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    services.sstorytime.database.createLocally = lib.mkDefault true;

    systemd.services.sstorytime = {
      description = "SSTorytime Server";
      serviceConfig = {
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = 5;
        ExecStart = ''
          ${lib.getExe' cfg.package "http_server"}
        '';
      };
      environment = {
        SST_SERVER_PORT = toString cfg.port;
        POSTGRESQL_URI = with cfg.database; "postgresql://${user}@${host}/${dbname}?sslmode=disable";
      };
      unitConfig = {
        StartLimitBurst = 5;
        StartLimitInterval = 100;
      };
      wantedBy = [
        "multi-user.target"
      ];
      after = [
        "network.target"
      ]
      ++ lib.optionals localDB [ "postgresql.target" ];
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [
      cfg.port
    ];

    services.postgresql = mkIf localDB {
      enable = true;
      ensureUsers = [
        {
          name = dbName;
          ensureDBOwnership = true;
        }
      ];
      ensureDatabases = [ dbName ];
    };
  };
}
