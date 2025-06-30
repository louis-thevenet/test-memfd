{
  description = "Nixpkgs with older glibc overlay";
  inputs = {
    # Latest stable nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    # Older nixpkgs that glibc 2.31
    # Easy to find with tools like https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=glibc
    nixpkgs-2-31 = {
      url = "github:NixOS/nixpkgs/3913f6a514fa3eb29e34af744cc97d0b0f93c35c";
      flake = false;
    };
    nixpkgs-2-35 = {
      url = "github:NixOS/nixpkgs/1b7a6a6e57661d7d4e0775658930059b77ce94a4";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs-25-05 = import nixpkgs { inherit system; };
      pkgs-2-31 = import ./nixpkgs/nixpkgs-2-31.nix { inherit inputs system; };
    in
    {
      packages.${system} = {
          name = "test-program";
          src = ./.;
          buildPhase = ''
            gcc main.c -o test-program
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp test-program $out/bin
          '';
        };
      };
      devShells.${system}.default = pkgs-2-31.mkShell {
        packages = [ pkgs-2-31.gcc ];
      };
    };
}
