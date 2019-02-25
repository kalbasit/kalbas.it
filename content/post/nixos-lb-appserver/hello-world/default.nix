{ buildGoPackage, lib }:

buildGoPackage rec {
  name = "hello-app-${version}";
  version = "0.0.1";

  # The GOPATH is defined to satisfy buildGoPackage, but is not going to be
  # used as we do not define any packages here besides the main package
  goPackagePath = "github.com/kalbasit/kalbas.it/content/post/nixos-lb-appserver/hello-world";

  src = ./.;

  meta = with lib; {
    description = "Hello World HTTP application";
    maintainers = with maintainers; [ kalbasit ];
    platforms = platforms.linux ++ platforms.darwin;
  };
}
