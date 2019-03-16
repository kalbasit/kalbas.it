let
  nixpkgs = import ./nixpkgs.nix;
in

# This allows overriding pkgs by passing `--arg pkgs ...`
{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;
with lib;

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

  defaultOptions.options = {
    author = mkOption { type = types.str; };
    baseURL = mkOption { type = types.str; };
    disqusShortname = mkOption { type = types.str; };
    enableRobotsTXT = mkOption { type = types.str; };
    footnoteReturnLinkContents = mkOption { type = types.str; };
    googleAnalytics = mkOption { type = types.str; };
    languageCode = mkOption { type = types.str; };
    languages = mkOption { type = with types; nullOr attrs; };
    layouts = mkOption { type = with types; listOf (either str path); };
    metaDataFormat = mkOption { type = types.str; };
    paginate = mkOption { type = types.str; };
    params = mkOption { type = with types; nullOr attrs; };
    permalinks.post = mkOption { type = types.str; };
    publishDir = mkOption { type = types.str; };
    static = mkOption { type = with types; listOf str; };
    theme = mkOption { type = types.str; };
    themesDir = mkOption { type = types.path; };
    title = mkOption { type = types.str; };
  };

  defaultConfig.config = {
    inherit themesDir theme;

    author = "Wael Nasreddine";
    baseURL = "https://kalbas.it/";
    disqusShortname = "kalbasit";
    enableRobotsTXT = "true";
    footnoteReturnLinkContents = "↩";
    googleAnalytics = "UA-82839578-2";
    languageCode = "en-us";
    layouts = [ "layouts" ];
    metaDataFormat = "yaml";
    paginate = "10";
    permalinks.post = "/:year/:month/:day/:slug";
    publishDir = "docs";
    static = [ "static" ];
    title = "kalbasit";
  };

  hugoConfig = lib.evalModules {
    modules = [
      defaultOptions
      defaultConfig
      {
        imports = [
          ./config/themes/gruvbox
          ./config/themes/terminal
        ];
      }
    ];
  };

  configFile = writeText "config.json" (builtins.toJSON hugoConfig.config);
in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    ln -nsf "${configFile}" config.json
  '';
 }
