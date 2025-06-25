{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/4dd072b68c5c146981b61634b58aa13a8f2d7ba2";

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      perSystem =
        {

          pkgs,
          ...
        }:
        {
          packages.default = pkgs.stdenv.mkDerivation {

            src = ./.;
            name = "test-memfd";
            nativeBuildInputs = with pkgs; [ gcc ];
            buildPhase = ''
              gcc main.c -o main
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp main $out/bin/
            '';
          };
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [ gcc ];
          };
        };
    };
}
