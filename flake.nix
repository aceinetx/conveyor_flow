{
  description = "conveyorflow";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "conveyorflow";
          version = "0.1.0";

          src = self;

          buildInputs = with pkgs; [
            makeWrapper
            zig
            libx11
            libxrandr
            libxinerama
            libxcursor
            libxi
            libGL
          ];

          configurePhase = ":";

          buildPhase = ''
            mkdir -p "$out/bin"
            mkdir -p "$out/.cache"
            cp * "$out/bin" -r

            zig build -Doptimize=ReleaseSmall --global-cache-dir $out/.cache/zig

            mv "$out/bin/conveyorflow" "$out/bin/conveyorflow-real"
            makeWrapper "$out/bin/conveyorflow-real" "$out/bin/conveyorflow" --set LD_LIBRARY_PATH "${pkgs.libglvnd}"
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            zig
            libx11
            libxrandr
            libxinerama
            libxcursor
            libxi
            libGL
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH}''${LD_LIBRARY_PATH:+:}${pkgs.libglvnd}/lib"
          '';
        };
      }
    );
}
