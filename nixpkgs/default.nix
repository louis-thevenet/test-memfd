{ inputs }:
let
  system = "x86_64-linux";
in
{
  # pkgs-25-05 = import inputs.nixpkgs { inherit system; };
  pkgs-2-31-recent = import ./nixpkgs-2-31-recent.nix { inherit inputs system; };
  # pkgs-2-35-recent = import ./nixpkgs-2-35-recent.nix { inherit inputs system; };
}
