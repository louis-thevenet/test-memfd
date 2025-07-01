{ inputs, system }:
let
  pkgs = inputs.nixpkgs;
  nixpkgs-old = inputs.nixpkgs-2-31;
  pkgs-old = import nixpkgs-old {
    inherit system;
  };

  glibc_2_31 = pkgs-old.glibc;

  gcc = pkgs.gcc-unwrapped.overrideAttrs (
    final: pred: {
      libc = glibc_2_31;
    }
  );

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
  stdenv-gcc_glibc_2_31 = getCustomGccStdenv gcc glibc_2_31 pkgs.stdenv pkgs;
in
stdenv-gcc_glibc_2_31
