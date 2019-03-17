{ pkgs ? import <nixpkgs> {}, domain ? "_" }:

let
  hello-world = pkgs.callPackage ./hello-world {};

  # makeBackend is a function that returns the configuration for a host serving
  # the hello-world application.
  makeBackend = {
    systemd.services.hello-world = {
      wantedBy = [ "multi-user.target" ];
      restartIfChanged = true;
      serviceConfig = {
        ExecStart = "${pkgs.lib.getBin hello-world}/bin/hello-world";
        RestartSec = "5";
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];
  };

in {
  network.description = "Load-balanced Hello World web application";
  network.enableRollback = true;

  backend1 = makeBackend;
  backend2 = makeBackend;

  lb = {
    networking.firewall.allowedTCPPorts = [ 80 ];

    services.nginx = {
      enable = true;
      upstreams = {
        "backend" = {
          servers = {
            "backend1:8080" = {};
            "backend2:8080" = {};
          };
        };
      };
      virtualHosts = {
        "${domain}" = {
          locations."/" = {
            proxyPass = "http://backend";
          };
        };
      };
    };
  };
}
