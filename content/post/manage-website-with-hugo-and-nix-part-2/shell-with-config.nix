let

  # See https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs for more information on pinning
  nixpkgs = builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixpkgs-unstable-2019-02-26";
    # Commit hash for nixos-unstable as of 2019-02-26
    url = https://github.com/NixOS/nixpkgs/archive/2e23d727d640f0a96b167d105157f6e7183d8f82.tar.gz;
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "15s7qjw4qm8mbimiv5fcg0nlgpx4gsws2kbx8z1qzqrid8jg76f8";
  };

in

{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

with pkgs;

let

  themes = {
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

    baseURL = "https://kalbas.it/";
  };

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);

in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    ln -nsf "${configFile}" config.json
  '';
}
