# This allows overriding pkgs by passing `--arg pkgs ...`
let
  nixpkgs = import ./nixpkgs.nix;
in

{ pkgs ? import nixpkgs {} }:

with pkgs;

let
  hugo-theme-terminal = pkgs.callPackage ./pkgs/themes/terminal {};
in

mkShell {
  buildInputs = [
    hugo

    nixops
  ];

  shellHook = ''
    mkdir -p themes
    ln -snf "${hugo-theme-terminal}" themes/hugo-theme-terminal
  '';
}
