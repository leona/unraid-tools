#!/bin/bash

timestamp() {
    date "+%Y-%m-%d-%H:%M:%S"
}

xecho() {
    local type="$1"
    local text="$2"
    local colour=$NOCOLOR;
    
    if [ -z "$text" ]; then 
        text=$1; type=""
    fi

    case $type in
        "warning")
            colour=$YELLOW
            ;;
        "error")
            colour=$RED
            ;;
        "success")
            colour=$GREEN
            ;;
    esac

    echo -e "${NOCOLOR}$(timestamp)\t${colour}${text}${NOCOLOR}" >&2
}

parse_job() {
    declare -n _src=$2
    declare -n _args=$3
    _src=$(echo "$1" | jq '.src' | xargs)
    _args=($(echo "$1" | jq -r '.args[]?'))
    xecho "success" "Got backup job - src: $_src args: ${_args[@]}"
}

find_single_path() {
    find $1 -maxdepth 0 2>/dev/null | head -1 | xargs
}

update_state() {
    local state=$1
    xecho "warning" "Updating daemon states to: $state"

    if [[ "$DRY_RUN" != "true" ]]; then
        /etc/rc.d/rc.docker $state
        /etc/rc.d/rc.libvirt $state

        if [[ "$state" == "stop" ]]; then # Fix for 'virtlogd is already running...'
            pkill virtlogd
            pkill virtlockd
        fi
    fi
}