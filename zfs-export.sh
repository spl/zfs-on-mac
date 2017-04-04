#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <pool>
Unmount a ZFS pool
END
)

if [[ $# -ne 1 ]] ; then
  echo "$USAGE"
  exit -1
fi

POOL=$1

/usr/bin/sudo /usr/local/bin/zpool export $POOL
