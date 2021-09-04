#!/bin/bash

source src/values.sh
source src/utilities.sh

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
xecho "success" "Finished"