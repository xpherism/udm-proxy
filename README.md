# Proxy for UDM Pro

Create a reverse proxy for UDM Pro.

Work based upon https://github.com/boostchicken-dev/udm-utilities/issues/149

## Prerequisities
- Create a proxy network (vlan 5, 10.0.5.1/24, no DHCP)
- Create port forwards, ie. WAN -> 10.0.5.4 (TCP/80,443) if needed
- Working **on_boot.d** setup (https://github.com/boostchicken/udm-utilities)

## Setup

Follow the steps below to get going

1. Download or clone this repository into /mnt/data/proxy.
2. Customize `on_boot.d/30-proxy.sh` to your needs.
3. Symlink container proxy boot script

    `$ ln -sf /mnt/data/proxy/on_boot.d/30-proxy.sh /mnt/data/on_boot.d/.`

4. Run boot script (to create/update network and create CNI configuration for container)

    `$ /mnt/data/on_boot.d/30-proxy.sh`

    It fail when trying to run the container, but thats okay, its just for setting op needed configuration before initial image run.

5. Register the container with podman

    `$ podman run -d --systemd=false --network proxy --name proxy -v "/mnt/data/proxy/Caddyfile:/etc/proxy/Caddyfile" xpherism:udm-proxy`

6. Run boot script again and we are done :-)

Remember to change the `etc/caddy/Caddyfile` to your requirements and add additional mounts to podman run if needed.<br>
The default caddefile proxies unifi.my.domain to 10.0.0.1 (ie. unifi controller)
If you keep the proxy settings for the unifi controller, then you need do following first to avoid redirect recursion

`$ ln -sf /mnt/data/proxy/etc/unifi-core/config.yaml /mnt/data/unifi-os/unifi-core/.`

This disabled http->https redirect from unifi controller which is the cause of the above problem.

## Image

Container image `xpherism:udm-proxy` is caddy built with the following modules
- proxy protocol (github.com/mastercactapus/caddy2-proxyprotocol)

Feel free to use the vanilla `caddy` docker image or roll your own depending on your needs.

To update container image, simple do

`$ podman stop proxy && podman rm proxy` and run boot script again :-)

For more information
- https://hub.docker.com/_/caddy
- https://caddyserver.com/docs/caddyfile
- https://github.com/mastercactapus/caddy2-proxyprotocol
- https://github.com/boostchicken/udm-utilities

To build your own image, simple fork this repository and change what you need and simple run

 `$ docker build --platform arm64 -t udm-proxy .`

## TODO
- Add DNS proxy DoH or DoT to `xpherism:udm-proxy` docker image
- If bored make a simple UI to reverse proxy :-)
