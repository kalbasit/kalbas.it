# This allows overriding pkgs by passing `--arg pkgs ...`
let
  nixpkgs = import ./nixpkgs.nix;
in

{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;

let
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
