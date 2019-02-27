{ fetchpatch, runCommand }:

let
  pinnedVersion = builtins.fromJSON (builtins.readFile ./version.json);
  pinned = builtins.fetchTarball {
    inherit (pinnedVersion) url sha256;
  };

  patches = [];

in

{
  theme = runCommand "hugo-theme-gruvbox-${pinnedVersion.rev}"
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
      author = "Wael Nasreddine";
      description = "Father - Entrepreneur - Architect - Engineer";
      keywords = [
        "blog"
        "golang"
        "gopher"
        "kalbasit"
        "programmer"
        "software architect"
        "software engineering"
      ];
      titlePrefix = "";
      titleSuffix = " | kalbas.it";
      dateFormat = "2006-01-02";
      menuItemPrefix = "~/";
      postTruncateLength = 250;
      hideGopher = false;
      disqusAutoLoad = true;
      disqusAutoLoadCount = true;
      googleAnalyticsTrackingId = "UA-82839578-2";

      menu = {
        links = {
          # name = "CV";
          # identifier = "cv.pdf";
          # url = "https://rawgit.com/bbrks/cv/master/cv.pdf";
          # weight = 9999;
        };
        social = {
          name = "LinkedIn";
          url = "https://www.linkedin.com/in/kalbasit/";
          weight = 100;
        };
      };
    };
  };
}
