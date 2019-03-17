---
title: "Website with NixOS/NixOPS. TLS automated with Let's Encrypt!"
date: 2019-02-27T18:50:58-08:00
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

{{< figure position="center" src="/assets/images/post/nixos-lb-appserver/design.svg" >}}

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

{{< code file="/content/post/nixos-lb-appserver/hello-world/main.go" language="go" >}}

And create a `hello-world/default.nix` so we can deploy this application in NixOS.

{{< code file="/content/post/nixos-lb-appserver/hello-world/default.nix" language="nix" >}}

### Servers

Define the servers we will be running for this demonstration by creating
the file `servers.nix` with the following content:

{{< code file="/content/post/nixos-lb-appserver/servers.nix" language="nix" >}}

This file defines our backends, as well as the the load balancer node.
This definitions is not deployable by itself as it's missing the
`deployment.target` declaration, this allows us to deploy the same set
of servers to multiple targets such as VirtualBox and AWS.

## Deployment

### VirtualBox

To deploy to VirtualBox, simply create the file `vbox.nix` with the
following content

{{< code file="/content/post/nixos-lb-appserver/vbox.nix" language="nix" >}}

Create a deployment by running `nixops create -d hw-vbox
servers.nix vbox.nix` and deploy it with `nixops deploy -d hw-vbox`

**NOTE**: if you run into an issue where NixOPS fails to deploy with an
error message matching `failed pre-init: VERR_INTERNAL_ERROR`, then you
should re-deploy with the `--force-reboot` flag. This is due to a [known
bug](https://github.com/NixOS/nixops/issues/908) that was fixed and
released in NixOS 19.03.

### AWS

We're going to deploy this configuration on AWS now. For AWS we need the
following resources:

- EC2 Security Groups:
  - ssh-in ingress TCP port 22 from 0.0.0.0/0.
  - http-in: ingress TCP port 80/443 from 0.0.0.0/0.
  - backend-http-in: ingress TCP port 8080 from rule http-in.
- EC2 instances:
  - 1x Load Balancer node attached to the http-in ec2 group.
  - 2x Backend nodes attached to the backend-http-in ec2 group.


## Usage

### VirtualBox

If the deployment went through without any issues, then the Hello, World
application should now be running on port 80 of the lb VirtualBox. You
can find the IP by running

{{< highlight console >}}
$ nixops info -f hw-vbox
Network name: hw-vbox
Network UUID: f0a28563-399a-11e9-9c18-0242570e97f8
Network description: Load-balanced Hello World web application
Nix expressions: /yl/code/.../kalbas.it/content/post/nixos-lb-appserver/servers.nix /yl/code/.../kalbas.it/content/post/nixos-lb-appserver/vbox.nix
Nix profile: /nix/var/nix/profiles/per-user/yl/nixops/f0a28563-399a-11e9-9c18-0242570e97f8

+----------+-----------------+------------+------------------------------------------------------+----------------+
| Name     |      Status     | Type       | Resource Id                                          | IP address     |
+----------+-----------------+------------+------------------------------------------------------+----------------+
| backend1 | Up / Up-to-date | virtualbox | nixops-f0a28563-399a-11e9-9c18-0242570e97f8-backend1 | 192.168.56.102 |
| backend2 | Up / Up-to-date | virtualbox | nixops-f0a28563-399a-11e9-9c18-0242570e97f8-backend2 | 192.168.56.103 |
| lb       | Up / Up-to-date | virtualbox | nixops-f0a28563-399a-11e9-9c18-0242570e97f8-lb       | 192.168.56.101 |
+----------+-----------------+------------+------------------------------------------------------+----------------+
{{< /highlight >}}

You can then use curl to watch load-balancing as it happens

{{< highlight html >}}
$ watch curl -qs http://192.168.56.101
# you should see backend1 alternating with backend2 in the following HTML output:
<!DOCTYPE html>
<html>
        <head>
                <title>Load-balanced application</title>
        </head>
        <body>
                <h1>Hello, World!</h1>
                <p>You are being serve this webpage from <strong>backend2</strong>.</p>
        </body>
</html>
{{< /highlight >}}
