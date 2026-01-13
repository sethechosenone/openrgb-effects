{
  description = "Custom effects for OpenRGB";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system}.default = pkgs.rustPlatform.buildRustPackage {
        pname = "openrgb-effects";
        version = "0.1.0";
        src = ./.;
        cargoLock.lockFile = ./Cargo.lock;
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          cargo
          rustc
          rust-analyzer
          clippy
          rustfmt
        ];
      };

      nixosModules.default = { config, lib, pkgs, ... }:
        with lib;
        let
          cfg = config.services.openrgb-effects;
        in {
          options.services.openrgb-effects = {
            enable = mkEnableOption "OpenRGB effects service";

            package = mkOption {
              type = types.package;
              default = self.packages.${system}.default;
              description = "The openrgb-effects package to use";
            };
          };

          config = mkIf cfg.enable {
            systemd.services.openrgb-effects = {
              description = "OpenRGB Custom Effects";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              serviceConfig = {
                ExecStart = "${cfg.package}/bin/openrgb-effects";
                Restart = "always";
                RestartSec = "10s";

                # Security hardening
                DynamicUser = true;
                SupplementaryGroups = [ "i2c" ]; # For SMBus access to RGB devices

                # Allow access to OpenRGB (usually runs on localhost:6742)
                PrivateNetwork = false;
              };
            };

            # Ensure OpenRGB server is running
            services.hardware.openrgb = {
              enable = mkDefault true;
              motherboard = mkDefault "amd";
            };
          };
        };
    };
}
