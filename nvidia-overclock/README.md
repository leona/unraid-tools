# Build container
```bash
docker build -t nxie/nvidia-overclock .
```

# List GPU uuids
```bash
docker run \
    --runtime=nvidia \
    --gpus=all \
    --rm \
    nxie/nvidia-overclock gpu_list
```

# Initial container setup
```bash
docker run \
    --runtime=nvidia \
    --privileged \
    --gpus=all \
    --name nvidia-overclock  \
    -v /mnt/user/appdata/nvidia-overclock/nvidia_driver_cache:/app/data \
    -v /boot/config/plugins/gpu-profile/gpu_profile.cfg:/etc/gpu_profile.cfg \
    nxie/nvidia-overclock apply
```

# Apply overclocks using setup container
```bash
docker start nvidia-overclock && docker logs nvidia-overclock -f --tail 10
```

# Test
docker run \
    --runtime=nvidia \
    --privileged \
    --gpus=all \
    -it \
    --rm \
    --name nvidia-overclock-test  \
    -v /mnt/disk1/appdata/nvidia-overclock/nvidia_driver_cache:/tmp \
    -v /boot/config/plugins/gpu-profile/gpu_profile.cfg:/etc/gpu_profile.cfg \
    nxie/nvidia-overclock /bin/bash