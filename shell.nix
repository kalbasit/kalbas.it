let
  nixpkgs = import ./nixpkgs.nix;
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;

let
  themes = {
    gruvbox = pkgs.callPackage ./pkgs/themes/gruvbox {};
    terminal = pkgs.callPackage ./pkgs/themes/terminal {};
  };

  themesDir = runCommand "hugo-themes"
    {
      preferLocalBuild = true;
    }
    ''
      mkdir $out
      ${builtins.concatStringsSep ";" (lib.mapAttrsToList
                                        (name: value: "ln -s ${value.theme} $out/${name}")
                                        themes)}
    '';

  hugoConfig = {
    inherit themesDir theme;

    author = "Wael Nasreddine";
    baseURL = "https://kalbas.it/";
    disqusShortname = "kalbasit";
    enableRobotsTXT = "true";
    footnoteReturnLinkContents = "↩";
    googleAnalytics = "UA-82839578-2";
    languageCode = "en-us";
    metaDataFormat = "yaml";
    paginate = "10";
    permalinks.post = "/:year/:month/:day/:slug";
    publishDir = "docs";
    title = "kalbasit";
  }
  # include the configuration that's specific for the theme
  // lib.optionalAttrs (themes."${theme}" ? config) themes."${theme}".config
  # include the layouts declared by the theme
  // lib.optionalAttrs (themes."${theme}" ? layouts) {
    layouts = [ "layouts" themes."${theme}".layouts ];
  }
  # include the static files declared by the theme
  // lib.optionalAttrs (themes."${theme}" ? static) {
    static = [ "static" themes."${theme}".static ];
  };

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);

in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    mkdir -p themes
    ln -nsf "${configFile}" config.json
  '';
 }
