---
title: "Manage Hugo themes with Nix"
date: 2019-02-27T00:00:00-08:00
tags:
  - nix
  - hugo
description: "Manage Hugo themes with Nix"
---

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
  theme specific must also live with the content specific assets.

# Proposed design

I'm going to discuss the solution I created to keep all the
configurations and all the files related to theme within the theme
folder.

My proposol is to store all of the configuration, the assets of the site
as well as the theme itself within the theme declaration. Modify the
`shell.nix` to generate the Hugo configuration from the global (or
content) configuration mixed with the configuration from the theme. And
to create symbolic links to all the files declared by the theme.

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
consider only the required settings in this section. We are then going
to use a function provided by nixpkgs called `writeText` to write the
configuration in a JSON format. To be clear, writeText takes two
arguments, the file name and the file contents as a string, so we have
to use a builtin function called `builtins.toJSON` to convert the set
into a JSON string that's fed to `writeText`.

{{< highlight nix >}}
{ pkgs ? import nixpkgs {}, theme ? "terminal" }:

let

  hugoConfig = {
    theme = "hugo-theme-${theme}"
    baseURL = "https://kalbas.it/";
  };

  configFile = writeText "config.json" (builtins.toJSON hugoConfig);
in

  ...
{{< /highlight >}}

Next, we should modify the shellHook to create a symbolic link of the
config by adding `ln -nsf "${configFile}" config.json` to it.
