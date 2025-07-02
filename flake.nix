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
      nixpkgs-old = inputs.nixpkgs-2-31;

      overlays.glibc-2-31 = final: prev: {
        # libxcrypt = pkgs-old.libxcrypt; # broken only in 2.35
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlays.glibc-2-31 ];
      };
      pkgs-old = import nixpkgs-old { inherit system; };

      # Get the old glibc and its development headers
      glibc_2_35 = pkgs-old.glibc;

      customStdenvComplete = pkgs.stdenvAdapters.overrideCC pkgs.stdenv (
        pkgs.buildPackages.wrapCCWith {
          cc = pkgs.gcc-unwrapped.overrideAttrs (old: {
            stdenv = customStdenvComplete;
            configureFlags = (old.configureFlags or [ ]) ++ [
              "--with-native-system-header-dir=${glibc_2_35.dev}/include"
              "--with-glibc-version=${glibc_2_35.version}"
            ];
          });
          bintools = pkgs.buildPackages.wrapBintoolsWith {
            bintools = pkgs.buildPackages.binutils-unwrapped;
            libc = glibc_2_35;
            inherit (pkgs.buildPackages) coreutils gnugrep;
          };
          libc = glibc_2_35;
          extraPackages = [ glibc_2_35.dev or glibc_2_35 ];
        }
      );
      overrideStdenv = pkg: pkg.override { stdenv = customStdenvComplete; };
      packages = [
        "hello"
        "perl"
        "gnumake"
      ];
    in
    {

      packages.${system} =
        {
          gcc = customStdenvComplete.cc;

          test-program = customStdenvComplete.mkDerivation {
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
        }
        // builtins.listToAttrs (
          map (pkgName: {
            name = pkgName;
            value = overrideStdenv pkgs.${pkgName};
          }) packages
        );
    };
}
