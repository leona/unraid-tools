### build
```bash
docker build -t nxie/tailscale .
```

### run
```bash
docker run \
    -v /mnt/user/appdata/tailscale-ams-exit:/var/lib/tailscale \
    --cap-add=NET_ADMIN --sysctl net.ipv4.ip_forward=1 --sysctl net.ipv6.conf.all.forwarding=1 \
    nxie/tailscale \
    --exit-node=tailscale_ip --accept-routes --advertise-routes=172.17.0.0/24
```

### Attach to network
```bash
docker run \
    --net=container:tailscale-ams-exit-net \
    ubuntu:impish
```