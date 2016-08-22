---
title: "blogging with style"
tags:
  - coreos
  - kubernetes
  - terraform
  - docker
categories:
  - Infrastructure
description: "describing how I setup my blog with AWS, CoreOS and docker"
menu: ""
banner: "images/posts/home-office-336378_640.jpg"
images:
date: "2016-08-21T18:21:02-07:00"
---

# Prelude

It's been quite some time since I shared my knowledge and the daily
challenges that I overcome. I always wanted to get back into writing as
it has always been therapeutic for me.

Opening Chrome and typing in a text box just don't feel right for a tech
blog. I feel the same about pushing to Github pages, I just didn't work
hard enough for that.

# Micro-Containerized cluster

The coolest ideal stack today would be:
- Etcd2 cluster with at least 5 nodes.
- Kubernetes cluster with at least 3 master nodes and 2 minion nodes.
- Let's encrypt generated SSL certificates for all websites.
- Route53 for managing the DNS zones.
- All managed using Terraform.

That's exactly what I did for work, but it's just way overkill and
financially unacceptable for a blog.

The stack I designed for this blog:
- One t2.micro instance running NginX containers with support for SSL
  certificates from Let's encrypt.
- Route53 for managing the DNS zones.
- All managed using Terraform.

<!--more-->

# The server

It's no brainier today for the choice of Operating system when it comes
to a server. CoreOS aces all categories as long as you are planning to
deploy containers.
