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

      pkgs-old = import nixpkgs-old { inherit system; };

      glibcOverlay =
        final: prev:
        let
          glibc =
            (pkgs-old.glibc.override {
              inherit (prev)
                callPackage
                ;
            }).overrideAttrs
              (attrs: {
                configureFlags = attrs.configureFlags ++ [
                  # new gcc has stricter error checking
                  "--disable-werror"
                ];
                # https://stackoverflow.com/a/77107152 this glibc needs older make
                depsBuildBuild = attrs.depsBuildBuild ++ [ prev.pkgsBuildBuild.gnumake42 ];
                makeFlags = [ "OBJCOPY=${prev.stdenv.cc.targetPrefix}objcopy" ];
                passthru = attrs.passthru // {
                  libgcc = prev.libgcc;
                };
              })
            // {
              # new nixpkgs has this as a separate output
              getent = glibc.bin;
              stdenv = prev.stdenv // {
                lib = glibc.lib;
              };
              pname = "glibc";
            };
        in
        {
          inherit glibc;
          inherit (inputs.nixpkgs-2-35) glibcLocales glibcIconv;
        };
      pkgs-old-glibc = import inputs.nixpkgs-2-35 {
        localSystem = system;
        overlays = [ glibcOverlay ];
        config.replaceStdenv =
          { pkgs }:
          pkgs.overrideCC pkgs.stdenv (
            pkgs.wrapCCWith {
              cc = pkgs.gcc-unwrapped.overrideAttrs (old: {
                configureFlags = (old.configureFlags or [ ]) ++ [
                  "--with-native-system-header-dir=${pkgs-old.glibc.dev}/include"
                  "--with-glibc-version=${pkgs-old.glibc.version}"
                ];
              });
              bintools = pkgs.wrapBintoolsWith {
                bintools = pkgs.binutils-unwrapped;
                libc = pkgs.glibc;
              };
              libc = pkgs.glibc;
            }
          );
        config.replaceBootstrapFiles =
          prevFiles:
          (pkgs-old.callPackage "${inputs.nixpkgs-2-35}/pkgs/stdenv/linux/make-bootstrap-tools.nix" { })
          .bootstrapFiles;
      };
    in
    {
      packages.${system} = {
        perl = pkgs-old-glibc.perl;
        test-program = pkgs-old-glibc.stdenv.mkDerivation {
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
