{ inputs, system }:
let
  nixpkgs = inputs.nixpkgs;
  nixpkgs-old = inputs.nixpkgs-2-35;
  pkgs-old = import inputs.nixpkgs-2-35 {
    inherit system;

  };
  glibcOverlay =
    final: prev:
    let
      glibcLocales = pkgs-old.glibcLocales.override {
        glibc = glibc;
      };
      glibc =
        (pkgs-old.glibc.override {
          inherit (prev)
            lib
            stdenv
            callPackage
            buildPackages
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
        };
    in
    {
      inherit glibc glibcLocales;
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
    config.replaceBootstrapFiles =
      prevFiles:
      (pkgs-old.callPackage "${nixpkgs-old}/pkgs/stdenv/linux/make-bootstrap-tools.nix" {
        #  localSystem = { inherit system; }; # Even older nixpkgs need localSystem
      }).bootstrapFiles;
  };
in
pkgs-overlaid
