#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <disk>

Mount a disk.
END
)

if [[ $# -ne 1 ]] ; then
  echo "$USAGE"
  exit -1
fi

DISK=$1

/usr/sbin/diskutil mount $DISK
