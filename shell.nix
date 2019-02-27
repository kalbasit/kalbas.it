# This allows overriding pkgs by passing `--arg pkgs ...`
let
  nixpkgs = import ./nixpkgs.nix;
in

{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;

let
  hugo-theme-gruvbox = pkgs.callPackage ./pkgs/themes/gruvbox {};
  hugo-theme-terminal = pkgs.callPackage ./pkgs/themes/terminal {};

  # TODO: Get rid of the if condition!
  activeTheme =
    if theme == "gruvbox" then hugo-theme-gruvbox
    else if theme == "terminal" then hugo-theme-terminal
    else null;

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
  } // activeTheme.config;

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);

in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    mkdir -p themes
    ln -nsf "${activeTheme.theme}" themes/hugo-theme-${theme}
    ln -nsf "${configFile}" config.json
  '' + lib.optionalString (activeTheme ? site) ''
    for sourcePath in $(find "${activeTheme.site}" -type f); do
      relativePath="''${sourcePath#${activeTheme.site}/}"
      targetPath="$PWD/$relativePath"
      mkdir -p "$(dirname "$targetPath")"
      ln -nsf "$sourcePath" "$targetPath"
    done
  '';
 }
