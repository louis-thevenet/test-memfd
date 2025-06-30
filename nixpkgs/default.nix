{ inputs }:
let
  system = "x86_64-linux";
in
inputs.nixpkgs-23-05.legacyPackages.${system}
