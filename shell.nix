let
  pinnedVersion = builtins.fromJSON (builtins.readFile ./.nixpkgs-version.json);
  pinnedPkgs = builtins.fetchTarball {
    inherit (pinnedVersion) url sha256;
  };
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? import pinnedPkgs {} }:

with pkgs;

mkShell {
  buildInputs = [
    hugo
  ];
}
