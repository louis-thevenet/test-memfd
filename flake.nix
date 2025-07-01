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
      nixpkgs-set = import ./nixpkgs/default.nix { inherit inputs; };
    in
    {
      packages.${system} =
        let
          build-test-program =
            pkgs:

            pkgs.stdenv.mkDerivation {
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

        in
        {
          inherit (nixpkgs-set)
            pkgs-25-05
            pkgs-2-31-recent
            pkgs-2-35-recent
            ;
        }
        // {
          test-program-latest = build-test-program nixpkgs-set.pkgs-25-05;
          test-program-2-31 = build-test-program nixpkgs-set.pkgs-2-31-recent;
          test-program-2-35 = build-test-program nixpkgs-set.pkgs-2-35-recent;
        };

    };
}
