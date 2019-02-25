---
title: "Website with NixOS/NixOPS, with automated let's encrypt"
date: 2019-02-24T18:50:58-08:00
tags:
  - nix
  - nixos
  - nixops
  - nginx
  - letsencrypt
categories:
  - Infrastructure
description: |
  How to use NixOPS to setup a web-server with automated Let's Encrypt
draft: true
---

# Overview

Working with Let's Encrypt can sometimes be quite difficult, especially
when setting up your own load balancer in front of your application
servers. This article give you a step by step instructions on how to
create a server, running [NixOS](https://nixos.org) and managed by
NixOPS.

# System Design

Let's first talk about the sytem design of our load-balanced
application. We want to run two replicas of a hello world application
(written in Go), behind a load balancer running NginX.

{{% figure position="center" src="/assets/images/post/nixos-lb-appserver/design.svg" %}}

# Getting ready

Skip this step if you have already installed Nix and NixOPS.

## Installing Nix

Nix can be installed by following the instructions
[here](https://nixos.org/nix/download.html). At the time of writing this
guide, Nix can be installed by simply running `curl
https://nixos.org/nix/install | sh` as a non-root user.

## Installing NixOPS

Once you have installed Nix, you can install nixops by running `nix-env
-f '<nixpkgs>' -iA nixops`.

## Create the Hello World application

This step guides you to create a hello world application in Go. It's
O.K. if you are not familiar with Go as we only use it here to write a
Hello, World web application.

Open up `hello-world/main.go` and type in the following contents:

{{% code file="/content/post/nixos-lb-appserver/hello-world/main.go" language="go" %}}

And create a `hello-world/default.nix` so we can deploy this application in NixOS.

{{% code file="/content/post/nixos-lb-appserver/hello-world/default.nix" language="nix" %}}

### Servers

Define the servers we will be running for this demonstration by creating
the file `servers.nix` with the following content:

{{% code file="/content/post/nixos-lb-appserver/servers.nix" language="nix" %}}

This file defines our backends, as well as the the load balancer node.
This definitions is not deployable by itself as it's missing the
`deployment.target` declaration, this allows us to deploy the same set
of servers to multiple targets such as VirtualBox and AWS.

## Deployment

### VirtualBox

To deploy to VirtualBox, simply create the file `vbox.nix` with the
following content

{{% code file="/content/post/nixos-lb-appserver/vbox.nix" language="nix" %}}

Create a deployment by running `nixops create -d hw-vbox
servers.nix vbox.nix` and deploy it with `nixops deploy -d hw-vbox --force-reboot`

**NOTE** that the `--force-reboot` should only be specified the first
time the deployment was done. This is due to a [known
bug](https://github.com/NixOS/nixops/issues/908).
