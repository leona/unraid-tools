##  Build container
```bash
docker build -t nxie/nvidia-overclock .
```

##  Initial container setup
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

##  Edit gpu_profile.cfg
```bash
gpu_profiles:
  d8ab80d4:
    pl: 300
    core: -50
    mem: 2000

gpu_default:
  pl: 300
  core: -100
  mem: 0
  powermizer: 1
  fan_control: 1
  fan_speed: 90
```

##  Apply overclocks
```bash
docker start nvidia-overclock && docker logs nvidia-overclock -f --tail 10
```