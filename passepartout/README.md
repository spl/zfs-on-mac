This directory contains instructions and scripts that I use for my particular
OpenZFS installation on macOS 10.12 (Sierra) with two 3 TB USB 3.0 external
drives.

The drives are named ADATA1 and Transcend1.

I created the ZFS pool with:

```
$ ../zfs-create-mirror-pool.sh passepartout \
  FE33AD56-C280-410B-B54B-85382CA84D75 \
  3A7DAF85-DBDB-49A7-AE9B-24D55CA27000
```

After plugging the USB cables in, I use the following scripts to quickly mount
(i.e. “import” in ZFS terminology) and unmount (“export”) the ZFS pool.

```
$ ./mount.sh
$ ./unmount.sh
```

The `zdb` output is in [`zdb.txt`](./zdb.txt).
