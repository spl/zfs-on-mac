#!/bin/bash

# Exit on error
set -e

USAGE=$(cat <<-END
Usage: $0 <volume>

Convert a disk partition (erasing everything!) to Core Storage.
END
)

if [[ $# -ne 1 ]] ; then
  echo "$USAGE"
  exit -1
fi

VOLUME=$1

/usr/sbin/diskutil coreStorage convert $VOLUME -passphrase
