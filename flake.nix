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
      pkgs = import nixpkgs { inherit system; };
      nixpkgs-old = inputs.nixpkgs-2-31;
      pkgs-old = import nixpkgs-old {
        inherit system;
      };

      glibc_2_31 = pkgs-old.glibc;

      gcc = pkgs.gcc-unwrapped;

      getCustomGccStdenv =
        customGcc: customGlibc: origStdenv:
        { pkgs, ... }:
        with pkgs;
        let
          compilerWrapped = wrapCCWith {
            cc = customGcc;
            bintools = wrapBintoolsWith {
              bintools = binutils-unwrapped;
              libc = customGlibc;
            };
          };
        in
        overrideCC origStdenv compilerWrapped;
      stdenv_glibc_2_31 = getCustomGccStdenv gcc glibc_2_31 pkgs.stdenv pkgs;
    in
    {
      packages.${system} =
        let
          build-test-program =
            pkgs:

            stdenv_glibc_2_31.mkDerivation {
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
          test = (build-test-program pkgs).overrideAttrs (
            final: prev: {
              stdenv = stdenv_glibc_2_31;
            }
          );
        };

    };
}
