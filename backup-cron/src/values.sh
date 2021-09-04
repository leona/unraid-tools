#!/bin/bash

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