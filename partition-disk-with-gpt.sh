#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <volume> <partion>

Partition the volume (erasing everything!) using the GUID Partitioning Table
(GPT) scheme required for Core Storage.
END
)

if [[ $# -ne 2 ]] ; then
  echo "$USAGE"
  exit -1
fi

VOLUME=$1
PARTITION=$2

/usr/sbin/diskutil eject $VOLUME || true
/usr/sbin/diskutil partitionDisk $VOLUME GPT JHFS+ $PARTITION 100%

# Notes:
#
# 1. We eject first because partitionDisk doesn't always work if the volume is
#    mounted.
#
# 2. The volumes must be given names (and not %noformat%) in order to be
#    formatted.
#
# 3. The partition intended for Core Storage (named ZFS here) must have a
#    journaled format. We use JHFS+ above.
