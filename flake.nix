{
  description = "Custom wave effects for OpenRGB";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        openrgb-effects = pkgs.rustPlatform.buildRustPackage {
          pname = "openrgb-effects";
          version = "1.0.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;

          meta = with pkgs.lib; {
            description = "Custom wave effects for OpenRGB";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.linux;
          };
        };
      in
      {
        packages = {
          default = openrgb-effects;
          openrgb-effects = openrgb-effects;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cargo
            rustfmt
            rust-analyzer
            clippy
          ];
        };
      }
    ) // {
      nixosModules = {
        default = { config, lib, pkgs, ... }: {
          imports = [];

          options = with lib; {
            services.openrgb-effects = {
              enable = mkEnableOption "OpenRGB effects service";

              package = mkOption {
                type = types.package;
                default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
                description = "The openrgb-effects package to use";
              };
            };
          };

          config = with lib; let
            cfg = config.services.openrgb-effects;
          in mkIf cfg.enable {
            systemd.services.openrgb-effects = {
              description = "OpenRGB Custom Wave Effects";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                ExecStart = "${cfg.package}/bin/openrgb-effects";
                Restart = "on-failure";
                RestartSec = "10s";
                Type = "simple";

                DynamicUser = true;
                SupplementaryGroups = [ "i2c" ];
                PrivateNetwork = false;
              };
            };

            services.hardware.openrgb = {
              enable = true;
              motherboard = mkDefault "amd";
            };
          };
        };

        openrgb-effects = self.nixosModules.default;
      };
    };
}
