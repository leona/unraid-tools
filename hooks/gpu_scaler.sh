#!/bin/bash

CONTAINER_NAME="aio-miner"
CONTAINER_ID=$(docker inspect --format="{{.Id}}" $CONTAINER_NAME)
INPUT_VM=$1
INPUT_EVENT=$2

update_container() {
    echo "Attaching to container: $1"
    local devices="$(echo "$1" | cut -d, -f"2" | xargs | sed -e 's/ /,/g')"
    local devices_escaped="$(echo $devices | sed 's/\-/\\-/g')"

    echo "cd /Container/Config[@Name='NVIDIA_VISIBLE_DEVICES']
    set $devices
    cd /Container/Environment/Variable[2]/Value
    set $devices
    save" | xmllint --shell /boot/config/plugins/dockerMan/templates-user/my-$CONTAINER_NAME.xml

    docker stop $CONTAINER_ID
    sed -i "s/\"NVIDIA_VISIBLE_DEVICES=[A-Za-z0-9,\-]*\"/\"NVIDIA_VISIBLE_DEVICES=$devices_escaped\"/g" /var/lib/docker/containers/$CONTAINER_ID/config.v2.json
    echo "Setting /var/lib/docker/containers/$CONTAINER_ID/config.v2.json to: $(cat /var/lib/docker/containers/$CONTAINER_ID/config.v2.json)"
    /etc/rc.d/rc.docker restart
}

get_vm_buses() {
    local buses=""

    while read -r bus; do
        bus=${bus#*'"'}; bus=${bus%'"'*}
        buses+="$bus|"
    done <<< $(xmllint --xpath '//domain/devices/hostdev[@type="pci"]/source/address/@bus' --nowarning /etc/libvirt/qemu/$INPUT_VM.xml | sort | uniq)
    
    echo "${buses%?}"
}

if [[ "$INPUT_EVENT" == "prepare" ]]; then
    buses="$(get_vm_buses)"

    if [ -z "$buses" ]; then
        exit 0
    fi
    echo "Ignoring: $buses"
    devices="$(nvidia-smi --query-gpu="pci.bus,uuid" --format=csv,noheader | grep -Evi "$buses")"
    update_container "$devices"
fi

if [[ "$INPUT_EVENT" == "release" ]]; then
    buses="$(get_vm_buses)"
    
    if [ -z "$buses" ]; then
        exit 0
    fi

    devices="$(nvidia-smi --query-gpu="pci.bus,uuid" --format=csv,noheader)"
    update_container "$devices"
    (docker start nvidia-overclock) &
fi

if [[ "$INPUT_EVENT" == "force-release" ]]; then
    devices="$(nvidia-smi --query-gpu="pci.bus,uuid" --format=csv,noheader)"
    update_container "$devices"
    (docker start nvidia-overclock) &
fi