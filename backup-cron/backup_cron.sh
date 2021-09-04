#!/bin/bash

# include: src/values.sh


# Config options
DEST="/mnt/user/backups"
LOG_PATH=/var/log/backup_task.log
DRY_RUN=true

# Constants
DATESTAMP=$(date "+%Y-%m-%d")
DAY_OF_WEEK=$(date +%u)
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
NOCOLOR=$'\033[0m'

# Backup paths and ignore rules
backup_jobs=$(cat <<'EOF'
[
    {
        "src": "/boot/",
        "args": ["*.log", "*.log*"]
    },
    {
        "src": "/mnt/user/appdata/",
        "args": ["*.log*", "*.pyc", "*.log"]
    },
    {
        "src": "/mnt/user/system/libvirt/"
    }
]
EOF
)
# include: src/utilities.sh


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

new_path="${DEST}/${DAY_OF_WEEK}_${DATESTAMP}"
current_path="$(find_single_path ${DEST}/${DAY_OF_WEEK}_*)"

# Output logs to $LOG_PATH and print them out
exec > >(tee -i $LOG_PATH)
exec 2>&1

# Disable IO actions when testing
if [[ "$DRY_RUN" == "true" ]]; then
cp() { echo "DRY_RUN Ignoring: cp $@"; }
mv() { echo "DRY_RUN Ignoring: mv $@"; }
rsync_extras="--dry-run"
fi

# Find and rename last backup
update_state "stop"

if [ -n "$current_path" ] && [[ "$current_path" != "$new_path" ]]; then
xecho "Found existing. Moving: $current_path To: $new_path "
mv $current_path $new_path
fi

# Go through backup jobs
xecho "warning" "Starting..."

echo "$(echo "$backup_jobs" | jq -c '.[]')" | while read -r job; do
parse_job "$job" src_path args
output_path="$new_path/$(basename $src_path)"
xecho "warning" "Backing up $src_path into $output_path - please wait..."
rsync $rsync_extras --exclude="${args[0]}" --exclude="${args[1]}" --exclude="${args[2]}" --mkpath -avXHg $src_path $output_path

if [[ "$?" != "0" ]]; then
xecho "error" "Rsync failed"
exit 1
fi
done

update_state "start"
