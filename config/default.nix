{ theme, pkgs }:

with pkgs.lib;

let
  themes = builtins.removeAttrs
    (pkgs.callPackage ../pkgs {}).themes
    [ "override" "overrideDerivation" ];

  themesDir = pkgs.runCommand "hugo-themes"
  {
    preferLocalBuild = true;
  }
  ''
    mkdir $out
    ${builtins.concatStringsSep
      ";"
      (mapAttrsToList (name: value: "ln -s ${value} $out/${name}") themes)}
  '';

  defaultOptions.options = {
    author = mkOption {
      type = types.str;
    };

    baseURL = mkOption {
      type = types.str;
    };

    disqusShortname = mkOption {
      type = types.str;
    };

    enableRobotsTXT = mkOption {
      type = types.str;
    };

    footnoteReturnLinkContents = mkOption {
      type = types.str;
    };

    googleAnalytics = mkOption {
      type = types.str;
    };

    languageCode = mkOption {
      type = types.str;
    };

    languages = mkOption {
      type = types.attrs;
      default = {};
    };

    layouts = mkOption {
      type = with types; listOf (either str path);
      default = [];
    };

    metaDataFormat = mkOption {
      type = types.str;
    };

    paginate = mkOption {
      type = types.str;
    };

    params = mkOption {
      type = with types; nullOr attrs;
    };

    permalinks.post = mkOption {
      type = types.str;
    };

    publishDir = mkOption {
      type = types.str;
    };

    social = mkOption {
      type = with types; nullOr attrs;
      default = {};
    };

    staticDir = mkOption {
      type = with types; listOf (either str path);
      default = [];
    };

    theme = mkOption {
      type = types.str;
    };

    themesDir = mkOption {
      type = types.path;
    };

    title = mkOption {
      type = types.str;
    };
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
    languages = {};
    layouts = [ "layouts" ];
    metaDataFormat = "yaml";
    paginate = "10";
    permalinks.post = "/:year/:month/:day/:slug";
    publishDir = "docs";
    staticDir = [ "static" ];
    title = "kalbasit";
  };

in evalModules {
  modules = [
    defaultOptions
    defaultConfig
    {
      imports = [
        ./themes/gruvbox
        ./themes/icarus
        ./themes/terminal
      ];
    }
  ];
}
