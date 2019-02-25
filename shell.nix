# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? import (import ./nixpkgs.nix) {} }:

with pkgs;

mkShell {
  buildInputs = [
    hugo

    nixops
  ];
}
