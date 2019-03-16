{ callPackage }:

{
  gruvbox = callPackage ./gruvbox {};
  terminal = callPackage ./terminal {};
  icarus = callPackage ./icarus {};
}
