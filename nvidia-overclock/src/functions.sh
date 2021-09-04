#!/bin/bash

GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
GRAY=$'\033[2;37m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

timestamp() {
    date "+%Y-%m-%d-%H%M%S"
}

parse_yaml() { # https://github.com/mrbaseman/parse_yaml
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|,$s\]$s\$|]|" \
        -e ":1;s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s,$s\(.*\)$s\]|\1\2: [\3]\n\1  - \4|;t1" \
        -e "s|^\($s\)\($w\)$s:$s\[$s\(.*\)$s\]|\1\2:\n\1  - \3|;p" $1 | \
   sed -ne "s|,$s}$s\$|}|" \
        -e ":1;s|^\($s\)-$s{$s\(.*\)$s,$s\($w\)$s:$s\(.*\)$s}|\1- {\2}\n\1  \3: \4|;t1" \
        -e    "s|^\($s\)-$s{$s\(.*\)$s}|\1-\n\1  \2|;p" | \
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)-$s[\"']\(.*\)[\"']$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)-$s\(.*\)$s\$|\1$fs$fs\2|p" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" | \
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]; idx[i]=0}}
      if(length($2)== 0){  vname[indent]= ++idx[indent] };
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) { vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, vname[indent], $3);
      }
   }'
}

gpu_short_id() {
    gpu_uuid=$(nvidia-smi -i $1 --query-gpu=uuid --format=csv,noheader)
    gpu_uuid_split=(${gpu_uuid//\-/ })
    gpu_uuid_short="${gpu_uuid_split[1]}"
    echo $gpu_uuid_short | xargs
}

gpu_bus_id() {
    nvidia-smi -i $1 --query-gpu=gpu_bus_id --format=csv,noheader | xargs |  awk -F'00000000:' '{ print $2 }'
}

gpu_vendor() {
    local bus_id=$(gpu_bus_id $1)
    echo "$(lspci -vnn 2> /dev/null | grep -iF "$bus_id" -A 12 | grep "Subsystem" | awk -F'Subsystem: ' '{ print $2 }' | awk -F'Device' '{ print $1 }' | xargs | cut -c 1-20)"
}

restart_x() {
    pkill X
    rm -f /tmp/.X0-lock
    xecho "warning" "Setting peristence mode"
    nvidia-smi -pm 1
    sleep 2
    xecho "warning" "Configuring xorg.conf"
    nvidia-xconfig --cool-bits=31 --allow-empty-initial-configuration --use-display-device=None --virtual=1920x1080 --no-overlay --no-render-accel --no-cioverlay --enable-all-gpus --no-separate-x-screens
    sleep 5
    xecho "warning" "Starting X server"
    xinit &
    sleep 2
}

xecho() {
    local type="$1"
    local text="$2"

    if [ -z "$text" ]; then
        local text=$1
        local colour=$NOCOLOR
    elif [[ "$type" == "warning" ]]; then
        local colour=$YELLOW
    elif [[ "$type" == "error" ]]; then
        local colour=$RED
    elif [[ "$type" == "success" ]]; then
        local colour=$GREEN
    fi

    if [ -z ${SILENT_LOG+x} ]; then
        echo -e "${NOCOLOR}$(timestamp)\t${colour}${text}${NOCOLOR}" >&2
    fi
}