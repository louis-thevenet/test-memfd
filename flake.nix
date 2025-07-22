{
  description = "Nixpkgs with older glibc overlay";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
  };
  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      packages.${system} = {
        test-program = pkgs.stdenv.mkDerivation {
          name = "test-program";
          src = ./.;
          buildPhase = ''
            $CC main.c -o test-program
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp test-program $out/bin
          '';
        };
      };
    };
}
