{
  description = "Nixpkgs with older glibc overlay";

  inputs = {
    # Latest stable nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/25.05";
    # Older nixpkgs that glibc 2.35-224
    # Easy to find with tools like https://lazamar.co.uk/nix-versions/?channel=nixpkgs-unstable&package=glibc
    nixpkgs-old.url = "github:NixOS/nixpkgs/1b7a6a6e57661d7d4e0775658930059b77ce94a4";
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
          inherit glibc;
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
            # Even older nixpkgs need localSystem:
            # localSystem = {
            #   inherit system;
            # };
          }).bootstrapFiles;
      };
    in
    {
      packages = {
        recent-gcc = pkgs-recent.gcc;
        older-gcc = pkgs-overlaid.gcc;
      };
      devShells.${system}.default = pkgs-overlaid.mkShell {
        buildInputs = with pkgs-overlaid; [
          gcc
        ];

      };
      overlays.default = glibcOverlay;
    };
}
