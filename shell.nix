let
  pinnedVersion = builtins.fromJSON (builtins.readFile ./.nixpkgs-version.json);
  pinnedPkgs = builtins.fetchTarball {
    inherit (pinnedVersion) url sha256;
  };
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? import pinnedPkgs {} }:

with pkgs;

let
  hugo-theme-terminal = pkgs.callPackage ./pkgs/themes/terminal {};
in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    mkdir -p themes
    ln -snf "${hugo-theme-terminal}" themes/hugo-theme-terminal
  '';
}
