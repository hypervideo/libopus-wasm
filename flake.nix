{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3a228057f5b619feb3186e986dbe76278d707b6e";
    flake-utils.url = "github:numtide/flake-utils/11707dc2f618dd54ca8739b309ec4fc024de578b";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        libopus-wasm = pkgs.callPackage ./default.nix { };
      in
      {
        packages = {
          inherit libopus-wasm;
        };
        devShells.default = pkgs.mkShell { };
      }
    );
}
