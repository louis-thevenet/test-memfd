{
  description = "Nixpkgs with older glibc overlay";
  inputs = {
    # Latest stable nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    # Older nixpkgs that glibc 2.31
    # Easy to find with tools like https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=glibc
    nixpkgs-old.url = "github:NixOS/nixpkgs/3913f6a514fa3eb29e34af744cc97d0b0f93c35c";
    nixpkgs-old.flake = false;
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-old,
    }:
    let
      system = "x86_64-linux";
      pkgs-recent = import nixpkgs { inherit system; };
      pkgs-old = import nixpkgs-old { inherit system; };
      glibcOverlay =
        final: prev:
        let
          glibc =
            (pkgs-old.glibc.override {
              inherit (prev)
                callPackage
                buildPackages
                ;
              stdenv = prev.stdenv // {
                lib = prev.lib;
              };
            }).overrideAttrs
              (attrs: {
                # Ensure pname and version are preserved (needed for glibc 2.31 but not 2.35)
                pname = attrs.pname or "glibc";
                version = attrs.version;

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
              });

          # Use the old glibc's locales without override, or create a compatible one
          glibcLocales =
            pkgs-old.glibcLocales
              or (pkgs-old.callPackage "${nixpkgs-old}/pkgs/development/libraries/glibc/locales.nix" {
                inherit (pkgs-old)
                  stdenv
                  buildPackages
                  callPackage
                  writeText
                  ;
                libc = glibc;
              });
        in
        {
          # Ensure the glibc has the required attributes
          glibc = glibc // {
            # new nixpkgs has this as a separate output
            getent = glibc.bin;
            # Ensure pname is available at the top level (needed for glibc 2.31 but not 2.35)
            pname = glibc.pname or "glibc";
            version = glibc.version;
          };
          inherit glibcLocales;
        };
      pkgs-overlaid = import nixpkgs {
        inherit system;
        overlays = [ glibcOverlay ];
        config.replaceStdenv =
          { pkgs }:
          pkgs.overrideCC pkgs.stdenv (
            pkgs.wrapCCWith {
              cc = pkgs.gcc-unwrapped;
              bintools = pkgs.wrapBintoolsWith {
                bintools = pkgs.binutils-unwrapped;
                libc = pkgs.glibc;
              };
              libc = pkgs.glibc;
            }
          );
      };
    in
    {
      packages.${system} = {
        gcc-old = pkgs-overlaid.gcc;
        gcc-new = pkgs-recent.gcc;
        test-program = pkgs-overlaid.stdenv.mkDerivation {
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
      devShells.${system}.default = pkgs-overlaid.mkShell {
        packages = [ pkgs-overlaid.gcc ];
      };
    };
}
