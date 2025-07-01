{ inputs, system }:
let
  pkgs = inputs.nixpkgs;
  nixpkgs-old = inputs.nixpkgs-2-31;
  pkgs-old = import nixpkgs-old {
    inherit system;
  };

  glibc_2_31 = pkgs-old.glibc;

  gcc = pkgs-old.gcc-unwrapped;

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
  gcc_glibc_2_31 = getCustomGccStdenv gcc glibc_2_31 pkgs.stdenv pkgs;
in
gcc_glibc_2_31
