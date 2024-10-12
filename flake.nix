{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      perSystem =
        { lib, pkgs, ... }:
        {
          packages.default = pkgs.beamPackages.mixRelease {
            pname = "epostillon";
            src = self;
            version = "0.1.0";
            mixNixDeps = import ./deps.nix {
              inherit (pkgs) beamPackages;
              inherit lib;
            };
          };
          devShells.default = pkgs.mkShell {
            packages =
              (with pkgs; [
                beam.packages.erlang_27.elixir_1_17
                python3Packages.pgcli
                nodePackages.npm
              ])
              ++ (lib.optional (pkgs.stdenv.isLinux) pkgs.inotify-tools)
              ++ (lib.optional (pkgs.stdenv.isDarwin) pkgs.darwin.apple_sdk.frameworks.CoreServices);
          };
        };
    };
}
