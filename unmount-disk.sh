#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <disk>
Unmount a disk, including a Core Storage logical volume
END
)

if [[ $# -ne 1 ]] ; then
  echo "$USAGE"
  exit -1
fi

DISK=$1

/usr/sbin/diskutil unmountDisk $DISK
