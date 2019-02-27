# This allows overriding pkgs by passing `--arg pkgs ...`
let
  nixpkgs = import ./nixpkgs.nix;
in

{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;

let
  hugo-theme-gruvbox = pkgs.callPackage ./pkgs/themes/gruvbox {};
  hugo-theme-terminal = pkgs.callPackage ./pkgs/themes/terminal {};

  hugoConfig = {
    theme = "hugo-theme-${theme}";
    author = "Wael Nasreddine";
    baseurl = "https://kalbas.it/";
    disqusShortname = "kalbasit";
    enableRobotsTXT = "true";
    footnoteReturnLinkContents = "↩";
    googleAnalytics = "UA-82839578-2";
    publishDir = "docs";
    languageCode = "en-us";
    metaDataFormat = "yaml";
    paginate = "10";
    title = "kalbasit";
    permalinks.post = "/:year/:month/:day/:slug";
  } // lib.optionalAttrs (theme == "gruvbox") {
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
          name = "CV";
          identifier = "cv.pdf";
          url = "https://rawgit.com/bbrks/cv/master/cv.pdf";
          weight = 9999;
        };
        social = {
          name = "LinkedIn";
          url = "https://uk.linkedin.com/in/bbrks";
          weight = 100;
        };
      };
    };
  } // lib.optionalAttrs (theme == "terminal") {
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

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);

in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    mkdir -p themes
    ln -snf "${hugo-theme-gruvbox}" themes/hugo-theme-gruvbox
    ln -snf "${hugo-theme-terminal}" themes/hugo-theme-terminal
    ln -snf "${configFile}" config.json
  '';
}
