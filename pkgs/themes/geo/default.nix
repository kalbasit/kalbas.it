{ fetchpatch, runCommand }:

let
  pinnedVersion = builtins.fromJSON (builtins.readFile ./version.json);
  pinned = builtins.fetchTarball {
    inherit (pinnedVersion) url sha256;
  };

  patches = [
    # Add support for large and x-large screens by limiting the numbers of
    # columns the sidebar is allowed to take to just two.
    ./add-support-for-large-and-xlarge-monitors.patch

    # Allow disabling comments by setting `disableComments` to true in the
    # front matter.
    ./allow-comments-to-be-disabled-per-page.patch
  ];

in runCommand "hugo-theme-geo-${pinnedVersion.rev}"
  {
    inherit pinned patches;

    preferLocalBuild = true;
  }
  ''
    cp -r $pinned $out
    chmod -R u+w $out

    for p in $patches; do
    echo "Applying patch $p"
    patch -d $out -p1 < "$p"
    done
  ''
