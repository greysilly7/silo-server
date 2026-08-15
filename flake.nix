{
  description = "Silo — self-hosted, Jellyfin-compatible media streaming server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      version = "0-unstable-${self.shortRev or self.dirtyShortRev or "dirty"}";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = self.packages.${system}.silo-server;
          silo-server = pkgs.callPackage ./nix/package.nix {
            inherit version;
            src = self;
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              go_1_26
              gopls
              golangci-lint
              nodejs_22
              pnpm_10
              pkg-config
              vips
              jellyfin-ffmpeg
              goose
            ];

            CGO_ENABLED = "1";
          };
        }
      );

      nixosModules.default = import ./nix/module.nix self;

      formatter = forAllSystems (system: (pkgsFor system).nixfmt-rfc-style);
    };
}
