---
title: "Manage Hugo themes with Nix"
date: 2019-02-27T00:00:00-08:00
tags:
  - nix
  - hugo
description: "Manage Hugo themes with Nix"
draft: true
highlight: true
---

This is the second article in the series of articles about Hugo and Nix.
If you have not read the [previous article]({{< ref
"manage-website-with-hugo-and-nix" >}}), please do so before reading
this article.

# Introduction

In this article, I'm going to explore how to manage Hugo themes with
Nix. But before I talk about how Nix can help here, let me lay out the
problems I find with Hugo themes.

A Hugo theme requires one or more of the following resources:

- The configuration located at `config.{json,toml,yaml}` must be
  modified with theme-specific configuration:
  - The name of the theme set with the key `theme`.
  - The parametes of the theme set with the key `params`.
- Any custom element, be it a layout override or a static asset that is
  theme specific must also live at the root of your project along with
  your content.

This coupling of the theme to your content makes it hard to switch
themes without having to remove all of the custom layouts, static assets
and configuration.

# Proposed design

My proposal is to rely on Nix to create the theme, mix-in the
configuration with the global one and expose the static assets for the
theme. All without having to pollute then content, by keeping all of
these files in the nix store and telling Hugo where to find them.

We're going to have to generate the entire configuration from Nix, so we
can control which theme to render and allow themes to override the
global configuration. We're also going to have to figure out a way to
store the theme, the layouts and static as well as the configuration for
it. We can use Nix sets to store all of these information.

# Implementation

## Extract the theme

In the previous article, I had the theme in-line in the
shell.nix. While this is usually fine, it can become a problem as you
extend the theme and it's recommended to put the themes in a new file.

Let's extract the `runCommand "hugo-theme-terminal"` into a file located
at `pkgs/themes/terminal`.

Below is the updated `shell.nix`

{{< code file="/content/post/manage-website-with-hugo-and-nix-part-2/shell-without-theme.nix" language="nix" >}}

And the newly created `pkgs/themes/terminal/default.nix`:

{{< code file="/content/post/manage-website-with-hugo-and-nix-part-2/pkgs/themes/terminal/default-theme-only.nix" language="nix" >}}

## Writing the configuration through Nix

In order for us to write the Hugo configuration, we must represent this
in Nix. For the sake of simplifying the configuration, we're going to
consider only the required settings in this section. I'm going to use a
function provided by nixpkgs called `writeText` to write the
configuration in a JSON format into a file. To be clear, writeText takes
two arguments, the file name and the file contents as a string, so we
have to use a builtin function called `builtins.toJSON` to convert the
set from Nix into a JSON string.

{{< highlight nix >}}
{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

let

  hugoConfig = {
    inherit theme;

    baseURL = "https://kalbas.it/";
  };

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);
in

  ...
{{< /highlight >}}

Next, we should modify the shellHook to create a symbolic link of the
config by adding `ln -nsf "${configFile}" config.json` to it.

## Writing all themes to Hugo theme folder

Hugo looks for themes in the folder named `themes` at the root of your
project, but this is actually configurable with the setting named
`themesDir`. We want to extend on our previous article by placing all
the themes in a specific folder somewhere in the nix store and tell Hugo
to point to that directory instead of looking in the site. This way, we
do not have to pollute the site with symbolic links to themes that might
get accidentaly versioned.

We're going to again rely on the `runCommand` function in nixpkgs to
create a directory and create a symbolic link to all the themes we have
defined.

Let's start off by putting all the themes in a set

{{< highlight nix >}}
themes = {
  terminal = pkgs.callPackage ./pkgs/themes/terminal {};
};
{{< /highlight >}}

Now we can simply iterate over the name/value of the themes set to
create the symbolic links:

{{< highlight nix >}}
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
{{< /highlight >}}

Let's discuss the code above in more details.

### lib.mapAttrsToList

The `lib.mapAttrsToList` takes two arguments, a function and a set. It
calls the function with the name and value of each item of the set and
returns the list of return values from the function.

### builtins.concatStringsSep

The `builtins.concatStringsSep` function, it takes two arguments a
string and a list.

{{< highlight console >}}
  λ  nix repl
 Welcome to Nix version 2.2. Type :? for help.

 nix-repl> builtins.concatStringsSep " " ["Hello," "World!"]
 "Hello, World!"
{{< /highlight >}}

## Final shell.nix

Putting this together, we should end up with the following `shell.nix`
that's capable of generating Hugo configuration once you enter nix-shell.

{{< code file="/content/post/manage-website-with-hugo-and-nix-part-2/shell-with-config.nix" language="nix" >}}

This should generate Hugo configuration that's quite similar to the
following:

{{< highlight json >}}
{
    "baseURL": "https://kalbas.it/",
    "theme": "terminal",
    "themesDir": "/nix/store/8nyvm0hjwl029f7y5b0gf22bhcf8ndm0-hugo-themes"
}
{{< /highlight >}}
