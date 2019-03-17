let
  nixpkgs = import ./nixpkgs.nix;
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;
with lib;

let

  hugoConfig = builtins.removeAttrs (pkgs.callPackage ./config { inherit pkgs theme; }).config [ "_module" ];

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);
in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    ln -nsf "${configFile}" config.json
  '';
 }
