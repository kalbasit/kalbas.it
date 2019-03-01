{ runCommand }:

{
  theme = runCommand "hugo-theme-terminal"
    {
      pinned = builtins.fetchTarball {
        # Descriptive name to make the store path easier to identify
        name = "hugo-theme-terminal-2019-02-25";
        # Commit hash for hugo-theme-terminal as of 2019-02-25
        url = https://github.com/panr/hugo-theme-terminal/archive/487876daf1ebdf389f03a2dfdf6923cea5258e6e.tar.gz;
        # Hash obtained using `nix-prefetch-url --unpack <url>`
        sha256 = "17gvqml1wl14gc0szk1kjxi0ya995bmpqqfcwn9jgqf3gdx316av";
      };

      patches = [];

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
