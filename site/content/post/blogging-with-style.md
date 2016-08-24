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

Opening Chrome and typing in a text box just doesn't feel right for a
tech blog. I feel the same about pushing to Github pages, I just haven't
work hard enough for that.

# Micro-Containerized cluster

The most ideal stack today would be:
- Etcd2 cluster with at least 5 nodes.
- Kubernetes cluster with at least 3 master nodes and 2 minion nodes.
- Let's encrypt generated SSL certificates for all websites.
- Route53 for managing the DNS zones.
- All managed using Terraform.

That's exactly what I did for work, but it's way overkill and
financially unacceptable for a blog.

The stack I designed for this blog:
- One t2.micro instance running NginX containers with support for SSL
  certificates from Let's encrypt.
- Route53 for managing the DNS zones.
- All managed using Terraform.

# Overview

We will start from the top down by looking first at the application
level, then we will take a look at the hosting, the deployment, the
server and finally the cloud provisioning.

<!--more-->

# The blog

I wanted something I could easily customize, and does not use many
resources on the server. I thought of writing my own Go server to serve
static files but why [re-invent the
wheel](https://github.com/search?utf8=%E2%9C%93&q=%22static+site+generator%22&type=Repositories&ref=advsearch&l=&l=)?
[Jekyll](https://github.com/jekyll/jekyll) is very popular but
[Hugo](https://gohugo.io/) is much nicer, getting quite popular and get
few more points for being written in Go.

# The hosting

Hosting a static website is quite common, there are many choices out
there but none of them offer a free SSL certificate from Let's Encrypt.

I'm using [Nginx](https://hub.docker.com/r/library/nginx/) container as
the server listening on HTTP and HTTPS.
[docker-gen](https://hub.docker.com/r/jwilder/docker-gen/) watches for
containers exporting the variable `VIRTUAL_HOST`. `docker-gen` uses that
information to generate a configuration file for Nginx to listen on the
domain `VIRTUAL_HOST` is assigned and forward the requests to the
container exporting the `VIRTUAL_HOST`. Basically, the main Nginx
container is our reverse proxy and SSL terminating container.

[Let's encrypt Nginx proxy
container](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/)
also watch containers exporting the variable `LETSENCRYPT_HOST` and
`LETSENCRYPT_EMAIL` to generate the SSL certificate via Let's Encrypt.

Here's all the systemd unit files for the hosting

`nginx.service`:
```
[Unit]
Description=The NGINX HTTP and reverse proxy server
Requires=docker.service data.mount
After=docker.service data.mount
[Service]
ExecStartPre=/bin/sh -c "docker inspect nginx >/dev/null 2>&1 && docker rm -f nginx || true"
ExecStartPre=/usr/bin/docker create --name nginx -p 80:80 -p 443:443 \
  -v /etc/nginx/conf.d \
  -v /etc/nginx/vhost.d \
  -v /usr/share/nginx/html \
  -v /data/nginx/certs:/etc/nginx/certs:ro \
  nginx
ExecStart=/usr/bin/docker start -a nginx
ExecStop=-/usr/bin/docker stop nginx
ExecStopPost=/usr/bin/docker rm -f nginx
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
```

`nginx-gen.service`:
```
[Unit]
Description=Automatically generate nginx configuration for serving docker containers
Requires=docker.service nginx.service
After=docker.service nginx.service
[Service]
ExecStartPre=/bin/sh -c "rm -f /tmp/nginx.tmpl && curl -Lo /tmp/nginx.tmpl https://raw.githubusercontent.com/jwilder/nginx-proxy/a72c7e6e20df3738ca365bf6c14598f6a8017500/nginx.tmpl"
ExecStartPre=/bin/sh -c "docker inspect nginx-gen >/dev/null 2>&1 && docker rm -f nginx-gen || true"
ExecStartPre=/usr/bin/docker create --name nginx-gen --volumes-from nginx \
	-v /tmp/nginx.tmpl:/etc/docker-gen/templates/nginx.tmpl:ro \
	-v /var/run/docker.sock:/tmp/docker.sock:ro \
	jwilder/docker-gen \
	-notify-sighup nginx -watch -only-exposed -wait 5s:30s \
	/etc/docker-gen/templates/nginx.tmpl /etc/nginx/conf.d/default.conf
ExecStart=/usr/bin/docker start -a nginx-gen
ExecStop=-/usr/bin/docker stop nginx-gen
ExecStopPost=/usr/bin/docker rm -f nginx-gen
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
```

`nginx-gen-letsencrypt.service`:
```
[Unit]
Description=Automatically generate lets encrypt certificates
Requires=docker.service nginx-gen.service
After=docker.service nginx-gen.service
[Service]
ExecStartPre=/bin/sh -c "docker inspect nginx-gen-letsencrypt >/dev/null 2>&1 && docker rm -f nginx-gen-letsencrypt || true"
ExecStartPre=/usr/bin/docker create --name nginx-gen-letsencrypt -e "NGINX_DOCKER_GEN_CONTAINER=nginx-gen" --volumes-from nginx \
  -v /data/nginx/certs:/etc/nginx/certs:rw \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  jrcs/letsencrypt-nginx-proxy-companion
ExecStart=/usr/bin/docker start -a nginx-gen-letsencrypt
ExecStop=-/usr/bin/docker stop nginx-gen-letsencrypt
ExecStopPost=/usr/bin/docker rm -f nginx-gen-letsencrypt
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
```

`nginx-provider.service`: This is only required to force the `nginx-gen`
to generate a valid configuration for `nginx` so `nginx` starts serving
the content provided by `nginx-gen-letsencrypt.service`
```
[Unit]
Description=Start the NginX provider
Requires=docker.service nginx-gen-letsencrypt.service
After=docker.service nginx-gen-letsencrypt.service
[Service]
ExecStartPre=/bin/sh -c "docker inspect nginx-provider >/dev/null 2>&1 && docker rm -f nginx-provider || true"
ExecStartPre=/usr/bin/docker create --name nginx-provider \
  -e VIRTUAL_HOST=http-only.kalbas.it nginx
ExecStart=/usr/bin/docker start -a nginx-provider
ExecStop=-/usr/bin/docker stop nginx-provider
ExecStopPost=/usr/bin/docker rm -f nginx-provider
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
```

And finally, here's the systemd unit file running my blog:

```
[Unit]
Description=The NGINX HTTP and reverse proxy server. For kalbas.it
Requires=docker.service nginx-provider.service
After=docker.service nginx-provider.service
[Service]
ExecStartPre=/bin/sh -c "docker inspect nginx-kalbas.it >/dev/null 2>&1 && docker rm -f nginx-kalbas.it || true"
ExecStartPre=/usr/bin/docker pull kalbasit/kalbas-it
ExecStartPre=/usr/bin/docker create --name nginx-kalbas.it \
  -e VIRTUAL_HOST=kalbas.it \
  -e LETSENCRYPT_HOST=kalbas.it \
  -e LETSENCRYPT_EMAIL=wael.nasreddine@gmail.com \
  kalbasit/kalbas-it
ExecStart=/usr/bin/docker start -a nginx-kalbas.it
ExecStop=-/usr/bin/docker stop nginx-kalbas.it
ExecStopPost=/usr/bin/docker rm -f nginx-kalbas.it
Restart=on-failure
RestartSec=10
[Install]
WantedBy=multi-user.target
```

You might have noticed that all the mounted volumes are mounted from
`/data`. I'm using [Elastic File-system](https://aws.amazon.com/efs/)
for the `/data` volume as I want to make sure that the new server
booting up can mount the same volume as the instance currently running.

## Alternatives

- [S3 Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html).
- Few CDNs like [CloudFront](https://aws.amazon.com/cloudfront/).
- [AppEngine](https://deciphertools.com/blog/google-app-engine-static-sites/).

All of them have their own Pros and Cons but none of them provides Let's
Encrypt possibility.

[Caddy](https://github.com/mholt/caddy) is a very promising server with
automatic Let's Encrypt support, but it [does not support automatic
docker container proxy as of
yet](https://github.com/mholt/caddy/issues/199).

I am considering switching my deployment to
[Traefik](https://github.com/containous/traefik) as it does exactly what
my setup does but with less containers. It's also in Go!

# The deployment

One of the best things I love about [Travis-CI](https://travis-ci.org),
is that it supports [native
deployments](https://docs.travis-ci.com/user/deployment). It supports
many providers but most importantly it supports a custom script.

At work, I've built a [deploy
script](https://github.com/publica-project/deploy-tools) that does the
following:
- Build a docker image, it requires `Rockerfile` rather than
  `Dockerfile` to allow me to build, tag and push the image.
- Deploy to Kubernetes cluster.

I have [forked the deploy
script](https://github.com/kalbasit/deploy-tools) and added support for
deploying to a server by SSH'ing to it, running `docker pull` on the
image and restarting the systemd service.

# The server

It's no brainier today that CoreOS is the OS of choice when it comes to
a Web Server. The ideal setup would be a CoreOS cluster, to allow the
servers to roll a CoreOS update but again it's not economical. See [How
to update the server]({{< ref "#how-to-update-the-server" >}}) below for
more details.

## How to update the server?

I've solved that by using an Elastic Load Balancer and have Terraform create an
instance before removing the current one and update the ELB with the new
instance ID.

# Cloud provisioning

I'm using Terraform to provision AWS. The server itself is provisioned
via cloud-config.

`web_server.tf`:
```
resource "aws_security_group" "web_server" {
  name_prefix = "web_server"
  description = "Allow HTTP, HTTPS and SSH from anywhere"
  vpc_id      = "${module.vpc_us-east-1.vpc_id}"

  tags {
    Name    = "web_server"
    http    = "yes"
    https   = "yes"
    ssh     = "yes"
    self    = "yes"
    out_pub = "yes"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server-allow-all-from-self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = "${aws_security_group.web_server.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server-allow-ssh-from-all" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.web_server.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server-allow-http-from-all" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.web_server.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server-allow-https-from-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.web_server.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server-allow-all-out" {
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.web_server.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "web_server_data" {
  name_prefix = "web_server"
  description = "Allow HTTP, HTTPS and SSH from anywhere"
  vpc_id      = "${module.vpc_us-east-1.vpc_id}"

  tags {
    Name = "web_server_data"
    nfs  = "yes"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "web_server_data-allow-all-from-web-server" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.web_server.id}"
  security_group_id        = "${aws_security_group.web_server_data.id}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_efs_file_system" "web_server_data" {
  tags {
    Name = "web_server_data"
    role = "web_server_data"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_efs_mount_target" "web_server_data" {
  count           = "${length(var.public_subnets["us-east-1"])}"
  file_system_id  = "${aws_efs_file_system.web_server_data.id}"
  subnet_id       = "${element(module.vpc_us-east-1.public_subnets, count.index)}"
  security_groups = ["${aws_security_group.web_server_data.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

// TODO(kalbasit): The `data` type does not support the count metadata as of
// Terraform v0.7.0. We will continue using the deperecated `resource` for
// `template_file` until the `data` supports it.
// See https://github.com/hashicorp/terraform/issues/7919
resource "template_file" "web_server-cloud-config" {
  count    = "${length(var.public_subnets["us-east-1"])}"
  template = "${file("${path.module}/templates/web_server-cloud-config.yml")}"

  vars {
    web_server_data_dns_name = "${element(aws_efs_mount_target.web_server_data.*.dns_name, count.index)}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web_server" {
  count                  = 1
  ami                    = "${data.aws_ami.coreos-stable.id}"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.web_server.id}"]
  subnet_id              = "${element(module.vpc_us-east-1.public_subnets, count.index)}"
  user_data              = "${element(template_file.web_server-cloud-config.*.rendered, count.index)}"

  tags {
    Name = "web_server-${count.index}"
    role = "web_server"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "web_server" {
  name            = "web-server"
  subnets         = ["${module.vpc_us-east-1.public_subnets}"]
  security_groups = ["${aws_security_group.web_server.id}"]

  listener {
    instance_port     = "80"
    instance_protocol = "tcp"
    lb_port           = "80"
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = "443"
    instance_protocol = "tcp"
    lb_port           = "443"
    lb_protocol       = "tcp"
  }

  instances                   = ["${aws_instance.web_server.*.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = "400"
  connection_draining         = true
  connection_draining_timeout = "400"

  tags {
    Name = "web_server"
    role = "lb"
  }
}
```
