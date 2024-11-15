+++
tags = ["qubes", "tailscale", "dns"]
date = "2024-11-14T20:00:00-08:00"
description = "This post goes over Tailscale configuration on QubesOS"
title = "Configure Tailscale DNS on Qubes OS"
highlight = true
css = []
scripts = []
+++

This post goes over configuring Tailscale DNS to support DNS resolution from other AppVMs using the Tailscale VM.

<!--more-->

This guide assumes you already have Tailscale configured in a TemplateVM and a
sys-tailscale AppVM is running Tailscaled for other AppVMs to use. If you don't have
Tailscale already configured, then please head over to
[taradiddles][taradiddles]' [excellent guide][guide] over on the Qubes forum.

We need to do the following on the **TemplateVM** to get it all configured:

- Create a systemd service that runs a script.
- Create the script that gets executed by the systemd service.
- Shutdown the TemplateVM and restart the AppVMs based on it.

Create `/etc/systemd/system/qubes-tailscaled-dns.service` with the following contents:

```conf
[Unit]
Description=Forward all DNS traffic to Tailscale
Requires=tailscaled.service
After=qubes-network.service

[Service]
Type=oneshot
ExecStart=/usr/bin/qubes-tailscaled-dns.sh start
ExecStop=/usr/bin/qubes-tailscaled-dns.sh stop
RemainAfterExit=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Create the script that's used by the service `/usr/bin/qubes-tailscaled-dns.sh` with the following contents:

```bash
#!/usr/bin/env bash

set -euo pipefail

tailscale_dns=100.100.100.100
readonly tailscale_dns

primary_dns=$(/usr/bin/qubesdb-read /qubes-primary-dns 2>/dev/null) || primary_dns=
secondary_dns=$(/usr/bin/qubesdb-read /qubes-secondary-dns 2>/dev/null) || secondary_dns=
readonly primary_dns secondary_dns

# Protect against empty DNS server list
if [[ -z "$primary_dns" ]] && [[ -z "$secondary_dns" ]]; then
    >&2 echo "No primary or secondary DNS servers configured, cannot continue"
    exit 1
fi

# Flush the current dnat-dns chain
nft flush chain ip qubes dnat-dns  # nft is used to interact with the firewall

for dns in $primary_dns $secondary_dns; do
    if [[ "$1" == "start" ]]; then
        nft add rule ip qubes dnat-dns ip daddr $dns udp dport 53 dnat to $tailscale_dns
        nft add rule ip qubes dnat-dns ip daddr $dns tcp dport 53 dnat to $tailscale_dns
    else
        nft add rule ip qubes dnat-dns ip daddr $dns udp dport 53 dnat to $dns
        nft add rule ip qubes dnat-dns ip daddr $dns tcp dport 53 dnat to $dns
    fi
done

```

Once all this is done, simply shutdown the TemplateVM and restart your sys-tailscale AppVM. You should be up and running with DNS working on any AppVM that's using sys-tailscale for networking.

[guide]: https://forum.qubes-os.org/t/19004
[taradiddles]: https://forum.qubes-os.org/u/taradiddles
