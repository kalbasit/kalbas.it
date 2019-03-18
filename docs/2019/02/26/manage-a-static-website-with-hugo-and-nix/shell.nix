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

{ pkgs ? import nixpkgs {} }:

with pkgs;

let

  hugo-theme-terminal = runCommand "hugo-theme-terminal" {
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
    chmod -R u+w $out

    for p in $patches; do
      echo "Applying patch $p"
      patch -d $out -p1 < "$p"
    done
  '';

in

mkShell {
  buildInputs = [
    hugo
  ];

  shellHook = ''
    mkdir -p themes
    ln -snf "${hugo-theme-terminal}" themes/hugo-theme-terminal
  '';
}
