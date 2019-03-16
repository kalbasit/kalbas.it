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

  config = {
    params = {
      contentTypeName = "post";
      themeColor = "orange";
      showMenuItems = 3;
    };
    languages = {
      en = {
        title = "kalbasit";
        subtitle = "Wael Nasreddine";
        keywords = "";
        menuMore = "Show more";
        readMore = "Read more";
        readOtherPosts = "Read other posts";
        params = {
          logo = {
            logoText = "λ kalbas.it";
            logoHomeLink = "/";
          };
        };
        menu = {
          main = [
            {
              identifier = "about";
              name = "About";
              url = "/about";
            }
          ];
        };
      };
    };
  };

  layouts = ./layouts;
}
