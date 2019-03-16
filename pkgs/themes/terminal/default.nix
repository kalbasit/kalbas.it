{ fetchpatch, runCommand }:

let
  pinnedVersion = builtins.fromJSON (builtins.readFile ./version.json);
  pinned = builtins.fetchTarball {
    inherit (pinnedVersion) url sha256;
  };

  patches = [];

in

{
  theme = runCommand "hugo-theme-terminal-${pinnedVersion.rev}"
    {
      inherit pinned patches;

      preferLocalBuild = true;
    }
    ''
      cp -r $pinned $out

      for p in $patches; do
      echo "Applying patch $p"
      patch -d $out -p1 < "$p"
      done
    '';
}
