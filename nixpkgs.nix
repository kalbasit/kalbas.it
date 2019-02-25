let
  pinnedVersion = builtins.fromJSON (builtins.readFile ./.nixpkgs-version.json);
  pinnedPkgs = builtins.fetchTarball {
    inherit (pinnedVersion) url sha256;
  };
in
  pinnedPkgs
