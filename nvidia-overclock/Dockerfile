FROM nvidia/cuda:11.2.1-base-ubuntu18.04

MAINTAINER leona
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /app

RUN set -ex \
  && apt-get update -y \
  && apt-get upgrade -y \
  && apt-get update -y \
  && apt-get install -y \
    wget \
    xterm \
    xinit \
    software-properties-common \
  && add-apt-repository -y ppa:graphics-drivers \
  && apt-get install -y \
    nvidia-driver-470 \
    nvidia-utils-470 \
    xserver-xorg-video-nvidia-470 \
    nvidia-opencl-dev \
    nvidia-settings

RUN apt-get install -y pciutils
RUN rm -rf /var/lib/apt/lists/*

ENV GPU_FORCE_64BIT_PTR=0
ENV GPU_MAX_HEAP_SIZE=100
ENV GPU_USE_SYNC_OBJECTS=1
ENV GPU_MAX_ALLOC_PERCENT=100
ENV GPU_SINGLE_ALLOC_PERCENT=100
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DISPLAY=:0
ENV NV_DRV_V=""
ENV NVIDIA_BUILD_OPTS="-a -n -q -X --install-libglvnd --ui=none --no-kernel-module"
ENV SRC_PATH=/var/lib/nvidia-overclock
ENV CFG_PATH=/etc/gpu_profile.cfg
ENV DATA_DIR=/app/data
ENV PATH="$SRC_PATH/bin:${PATH}"
COPY /src $SRC_PATH
RUN chmod -R +x $SRC_PATH