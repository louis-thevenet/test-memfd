{ inputs, system }:
let
  nixpkgs = inputs.nixpkgs;
  nixpkgs-old = inputs.nixpkgs-2-31;
  pkgs-old = import nixpkgs-old {
    inherit system;
  };

  pkgs-temp = import inputs.nixpkgs { inherit system; };

  pkgs = import nixpkgs-old {
    inherit system;

    config = {
      replaceBootstrapFiles =
        prevFiles:
        let
          oldBootstrapTools =
            pkgs-old.callPackage "${nixpkgs-old}/pkgs/stdenv/linux/make-bootstrap-tools.nix"
              { };
          bootstrap = pkgs-old.callPackage "${nixpkgs-old}/pkgs/stdenv/linux/stdenv-bootstrap-tools.nix" {
            inherit (oldBootstrapTools)
              coreutilsMinimal
              tarMinimal
              bootGCC
              bootBinutils
              busyboxMinimal
              ;
            libc = pkgs-old.glibc;
          };
        in
        bootstrap.bootstrapFiles;
    };

    # We need to override packages that won't compile against the old glibc, e.g. zlib
    overlays = [

      (final: prev: {
        glibc =

          (pkgs-old.glibc).overrideAttrs (attrs: {
            configureFlags = (attrs.configureFlags or [ ]) ++ [
              "--disable-werror"
            ];
            passthru = (attrs.passthru or { }) // {
              libgcc = prev.libgcc;
            };
          })
          // {
            pname = "glibc";
          };
        zlib = pkgs-old.zlib;
        expand-response-params = pkgs-temp.expand-response-params; # Won't compile with glibc-2.31 AND doesn't exist in pkgs-old
        xz = pkgs-old.xz;
        file = pkgs-old.file;
        bash = pkgs-old.bash;
      })
    ];
  };

in
pkgs
