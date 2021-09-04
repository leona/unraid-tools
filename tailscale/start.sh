#!/bin/bash
mkdir /dev/net && mknod /dev/net/tun c 10 200
systemctl start tailscaled
tailscale up "$@"
systemctl stop tailscaled
tailscaled