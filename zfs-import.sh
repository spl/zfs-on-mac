#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <pool>
Mount a ZFS pool
END
)

if [[ $# -ne 1 ]] ; then
  echo "$USAGE"
  exit -1
fi

POOL=$1

/usr/bin/sudo /usr/local/bin/zpool import -d /var/run/disk/by-id/ $POOL

# Notes:
#
# * An alternative would be to use a `cachefile` as follows:
#
#   /usr/bin/sudo /usr/local/bin/zpool import -c $PWD/zpool.cache $POOL
